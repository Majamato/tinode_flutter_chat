import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_media_compressor.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession remote;
  late MemoryFileStore files;
  late ChatDatabase database;
  late FakeMediaCompressor compressor;
  late CachedTinodeSession session;
  late List<OutboxEvent> events;

  /// A 3 MB limit: at the default bitrates, about 13 seconds of video.
  const limits = TinodeAttachmentLimits(maxVideoBytes: 3 * 1024 * 1024);

  /// Just too large to go as it is, so it has to be compressed.
  final overLimit = limits.maxVideoBytes + 1;

  /// Just too large once compressed, even with the encoder's tolerance.
  final overCeiling = limits.compressedVideoBytesLimit(null) + 1;

  CachedTinodeSession open() {
    final session = CachedTinodeSession(
      remote,
      ChatStore(database),
      userId: alice,
      files: files,
      compressor: compressor,
      attachmentLimits: limits,
    );
    addTearDown(session.close);
    session.outbox.listen(events.add);
    return session;
  }

  setUp(() {
    remote = FakeTinodeSession(chats: [chat(bob, name: 'Bob')])
      ..loggedIn = true;
    files = MemoryFileStore();
    database = ChatDatabase(NativeDatabase.memory());
    compressor = FakeMediaCompressor(poster: Uint8List.fromList([7, 7, 7]))
      ..videoLength = 1000;
    events = [];
    session = open();
  });

  /// Lets the compressor, the uploader and the drain run to rest.
  Future<void> idle() async {
    for (var i = 0; i < 40; i++) {
      await settle();
    }
  }

  PickedFile video({int? length}) => pickedFile(
    'clip.mov',
    List.filled(length ?? overLimit, 1),
    mimeType: 'video/quicktime',
    isVideo: true,
  );

  PickedFile photo() =>
      pickedFile('a.png', pngBytes, mimeType: 'image/png', isImage: true);

  Iterable<String> callsStarting(String prefix) =>
      remote.calls.where((c) => c.startsWith(prefix));

  group('a video', () {
    test('is compressed, then uploaded and sent with its poster', () async {
      await session.sendAttachment(bob, video(), caption: 'Look');
      await idle();

      expect(compressor.calls, ['video $overLimit']);
      expect(
        remote.calls,
        containsAllInOrder(['upload clip.mp4', 'publish $bob   Look']),
      );
      final drafty =
          (remote.histories[bob]!.single.content as DraftyContent).drafty;
      final sent = drafty.videos.single;
      expect(sent.mimeType, 'video/mp4');
      expect(sent.name, 'clip.mp4');
      expect((sent.width, sent.height), (1280, 720));
      expect(sent.duration, const Duration(seconds: 10));
      expect(sent.preview, [7, 7, 7]);
      expect(sent.previewMimeType, 'image/jpeg');
      expect(sent.ref, isNotNull);
      expect(drafty.caption, 'Look');
      expect(await session.storedOutgoing(bob), isEmpty);
      expect(files.stagedIds, isEmpty);
    });

    test('shows at once with its poster, still to compress', () async {
      compressor.videoSteps = StreamController<double>();
      final queued = await session.sendAttachment(bob, video());

      final attachment = queued.attachment!;
      expect(attachment.isVideo, isTrue);
      expect(attachment.pendingCompression, isTrue);
      expect(attachment.poster, [7, 7, 7]);
      expect(attachment.duration, const Duration(seconds: 10));
      await compressor.videoSteps!.close();
    });

    test('a portrait video stored on its side shows upright', () async {
      compressor
        ..videoSteps = StreamController<double>()
        // A 2×3 PNG still: the poster is upright.
        ..poster = (Uint8List.fromList(pngBytes)
          ..setRange(16, 24, const [0, 0, 0, 2, 0, 0, 0, 3]));
      final queued = await session.sendAttachment(bob, video());

      final attachment = queued.attachment!;
      expect((attachment.width, attachment.height), (720, 1280));
      await compressor.videoSteps!.close();
    });

    test('a landscape video keeps its size', () async {
      compressor
        ..videoSteps = StreamController<double>()
        // A 3×2 PNG still.
        ..poster = pngBytes;
      final queued = await session.sendAttachment(bob, video());

      final attachment = queued.attachment!;
      expect((attachment.width, attachment.height), (1280, 720));
      await compressor.videoSteps!.close();
    });

    test('reports compression, then upload progress', () async {
      final steps = compressor.videoSteps = StreamController<double>();
      remote.uploadChunk = 400;
      await session.sendAttachment(bob, video());
      await idle();

      steps.add(0.42);
      await idle();
      expect(events.whereType<CompressProgress>().map((e) => e.fraction), [
        0,
        0.42,
      ]);
      expect(events.whereType<UploadProgress>(), isEmpty);
      expect(callsStarting('upload'), isEmpty);

      await steps.close();
      await idle();
      final progress = events
          .where((e) => e is CompressProgress || e is UploadProgress)
          .toList();
      expect(progress.last, isA<UploadProgress>());
      expect((progress.last as UploadProgress).fraction, 1);
      expect(remote.histories[bob], hasLength(1));
    });

    test("that can't fit is refused by size before it is queued", () async {
      compressor.info = const VideoInfo(duration: Duration(minutes: 3));

      await expectLater(
        session.sendAttachment(bob, video()),
        throwsA(
          isA<FileTooLargeException>().having(
            (e) => e.limit,
            'limit',
            limits.maxVideoBytes,
          ),
        ),
      );
      expect(await session.storedOutgoing(bob), isEmpty);
      expect(files.stagedIds, isEmpty);
      expect(compressor.calls, isEmpty);
    });

    PickedFile picked({required int length}) => PickedFile(
      name: 'clip.mov',
      length: length,
      openRead: () => Stream.value(const [1, 2, 3]),
      path: '/picked/clip.mov',
      isVideo: true,
    );

    test('as long and large as can be picked is staged', () async {
      compressor.info = VideoInfo(duration: limits.maxSourceVideoDuration);

      final staged = await session.stageAttachment(
        picked(length: limits.maxSourceVideoBytes),
      );

      expect(files.stagedIds, [staged.stagedId]);
      expect(staged.duration, limits.maxSourceVideoDuration);
      expect(await session.storedOutgoing(bob), isEmpty);
    });

    test('larger than can be picked is refused before it is copied', () async {
      await expectLater(
        session.stageAttachment(picked(length: limits.maxSourceVideoBytes + 1)),
        throwsA(
          isA<FileTooLargeException>().having(
            (e) => e.limit,
            'limit',
            limits.maxSourceVideoBytes,
          ),
        ),
      );
      expect(files.stagedIds, isEmpty);
    });

    test('longer than can be picked is refused before it is copied', () async {
      compressor.info = VideoInfo(
        duration: limits.maxSourceVideoDuration + const Duration(seconds: 1),
      );

      await expectLater(
        session.stageAttachment(picked(length: overLimit)),
        throwsA(
          isA<VideoTooLongException>().having(
            (e) => e.limit,
            'limit',
            limits.maxSourceVideoDuration,
          ),
        ),
      );
      expect(files.stagedIds, isEmpty);
    });

    group('trimmed', () {
      const minute = Duration(minutes: 1);
      final trim = VideoTrim(minute, minute * 2);

      Future<OutgoingAttachment> staged() {
        compressor.info = const VideoInfo(duration: Duration(minutes: 30));
        return session.stageAttachment(video());
      }

      test('compressed again, smaller, keeps its part', () async {
        compressor
          ..videoLength = overCeiling
          ..smallerVideoLength = 1000;
        final trimmed = await session.trimStaged(await staged(), trim);

        await session.sendStaged(bob, trimmed);
        await idle();

        expect(compressor.calls.last, startsWith('smaller video'));
        expect(compressor.trims, [trim, trim]);
        expect(remote.histories[bob], hasLength(1));
      });

      test('compresses only its part, and says how long that is', () async {
        final trimmed = await session.trimStaged(await staged(), trim);

        await session.sendStaged(bob, trimmed);
        await idle();

        expect(compressor.trims, [trim]);
        final sent = (remote.histories[bob]!.single.content as DraftyContent)
            .drafty
            .videos
            .single;
        expect(sent.duration, minute);
      });

      test('however long the video, is not refused', () async {
        final trimmed = await session.trimStaged(await staged(), trim);

        await expectLater(session.sendStaged(bob, trimmed), completes);
      });

      test('within the limit still has to be cut', () async {
        compressor.info = const VideoInfo(duration: Duration(minutes: 5));
        final whole = await session.stageAttachment(video(length: 1000));
        expect(whole.pendingCompression, isFalse);

        final trimmed = await session.trimStaged(whole, trim);
        await session.sendStaged(bob, trimmed);
        await idle();

        expect(compressor.calls, ['video 1000']);
        expect(compressor.trims, [trim]);
      });

      test('takes a new poster from where its part starts', () async {
        final original = await staged();
        compressor.poster = Uint8List.fromList([9, 9]);

        final trimmed = await session.trimStaged(original, trim);

        expect(compressor.posterTimes, [Duration.zero, minute]);
        expect(trimmed.poster, [9, 9]);
      });

      test('from the very start keeps the poster it has', () async {
        final trimmed = await session.trimStaged(
          await staged(),
          const VideoTrim(Duration.zero, minute),
        );

        expect(compressor.posterTimes, [Duration.zero]);
        expect(trimmed.poster, [7, 7, 7]);
      });

      test('an app closed while compressing cuts the same part', () async {
        final folder = Directory.systemTemp.createTempSync('outbox');
        addTearDown(() => folder.deleteSync(recursive: true));
        final file = File('${folder.path}/chat.sqlite');
        FakeTinodeSession link() =>
            FakeTinodeSession(chats: [chat(bob, name: 'Bob')])..loggedIn = true;
        await session.close();
        remote = link();
        database = ChatDatabase(NativeDatabase(file));
        session = open();
        compressor.videoSteps = StreamController<double>();
        final trimmed = await session.trimStaged(await staged(), trim);
        await session.sendStaged(bob, trimmed);
        await idle();
        await session.close();
        await compressor.videoSteps!.close();
        compressor.videoSteps = null;

        remote = link();
        database = ChatDatabase(NativeDatabase(file));
        session = open();
        await idle();

        expect(compressor.trims, [trim, trim]);
        expect(remote.histories[bob], hasLength(1));
      });
    });

    test('within the limit goes as it is, however long', () async {
      compressor.info = const VideoInfo(
        duration: Duration(minutes: 5),
        width: 1280,
        height: 720,
      );

      final queued = await session.sendAttachment(bob, video(length: 1000));
      expect(queued.attachment!.pendingCompression, isFalse);
      expect(queued.attachment!.poster, [7, 7, 7]);
      expect(queued.attachment!.duration, const Duration(minutes: 5));
      await idle();

      expect(compressor.calls, isEmpty);
      expect(events.whereType<CompressProgress>(), isEmpty);
      expect(callsStarting('upload'), ['upload clip.mov']);
      final sent = (remote.histories[bob]!.single.content as DraftyContent)
          .drafty
          .videos
          .single;
      expect(sent.mimeType, 'video/quicktime');
      expect(sent.preview, [7, 7, 7]);
      expect((sent.width, sent.height), (1280, 720));
    });

    test('exactly at the limit goes as it is', () async {
      await session.sendAttachment(bob, video(length: limits.maxVideoBytes));
      await idle();

      expect(compressor.calls, isEmpty);
      expect(remote.histories[bob], hasLength(1));
    });

    test('a lower server limit counts', () async {
      remote.serverInfo = const ServerInfo(
        version: '0.25',
        maxFileUploadSize: 2 * 1024 * 1024 + 500000,
      );
      compressor.videoLength = 1000;

      await session.sendAttachment(
        bob,
        video(length: 2 * 1024 * 1024 + 500001),
      );
      await idle();

      expect(compressor.calls, ['video ${2 * 1024 * 1024 + 500001}']);
    });

    test('over the limit once compressed is compressed again, smaller, at '
        'a bitrate cut by as much as the encoder overshot, and sent', () async {
      // As an encoder that won't go below a minimum quality does.
      compressor
        ..videoLength = overCeiling
        ..smallerVideoLength = 1000;

      await session.sendAttachment(bob, video());
      await idle();

      final bitrate = limits.secondPassVideoBitrate(
        asked: limits.videoBitrate,
        outputBytes: overCeiling,
        duration: const Duration(seconds: 10),
        limitBytes: limits.maxVideoBytes,
      );
      expect(bitrate, lessThan(limits.videoBitrate));
      expect(compressor.calls, [
        'video $overLimit',
        'smaller video $overLimit at $bitrate',
      ]);
      expect(callsStarting('upload'), ['upload clip.mp4']);
      expect(remote.histories[bob], hasLength(1));
      expect(await session.storedOutgoing(bob), isEmpty);
    });

    test('compressed again, its progress starts over', () async {
      compressor
        ..videoLength = overCeiling
        ..smallerVideoLength = 1000;
      await session.sendAttachment(bob, video());
      await idle();

      expect(events.whereType<CompressProgress>().map((e) => e.fraction), [
        0,
        0,
      ]);
    });

    test('a little over the limit once compressed is still sent', () async {
      // An encoder that missed its bitrate, within the tolerance.
      compressor.videoLength = limits.maxVideoBytes + 1;

      await session.sendAttachment(bob, video());
      await idle();

      expect(compressor.calls, ['video $overLimit']);
      expect(callsStarting('upload'), ['upload clip.mp4']);
    });

    test('within the limit once compressed is not compressed again', () async {
      await session.sendAttachment(bob, video());
      await idle();

      expect(compressor.calls, ['video $overLimit']);
    });

    test('still too large compressed smaller is not sent', () async {
      compressor.videoLength = overCeiling;

      await session.sendAttachment(bob, video());
      await idle();

      expect(compressor.calls.last, startsWith('smaller video'));
      final outgoing = (await session.storedOutgoing(bob)).single;
      expect(outgoing.status, OutgoingStatus.failed);
      expect(outgoing.failure, ChatFailure.tooLarge);
      expect(callsStarting('upload'), isEmpty);
    });

    test("a format the device can't decode fails as such", () async {
      compressor.failure = const UnsupportedVideoFormatException('audio/ac3');

      await session.sendAttachment(bob, video());
      await idle();

      final outgoing = (await session.storedOutgoing(bob)).single;
      expect(outgoing.failure, ChatFailure.unsupportedFormat);
      expect(callsStarting('upload'), isEmpty);
    });

    test('a failed compression marks the message not sent', () async {
      compressor.failure = Exception('no encoder');

      await session.sendAttachment(bob, video());
      await idle();

      final outgoing = (await session.storedOutgoing(bob)).single;
      expect(outgoing.failure, ChatFailure.unexpected);
      expect(callsStarting('upload'), isEmpty);
    });

    test('discarded while compressing stops it', () async {
      compressor.videoSteps = StreamController<double>();
      final queued = await session.sendAttachment(bob, video());
      await idle();

      await session.discard(queued.clientId);
      await idle();

      expect(compressor.calls, ['video $overLimit', 'cancel']);
      expect(await session.storedOutgoing(bob), isEmpty);
      expect(files.stagedIds, isEmpty);
      expect(callsStarting('upload'), isEmpty);
    });

    test('compresses offline, and uploads once connected', () async {
      remote.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));
      await session.sendAttachment(bob, video());
      await idle();

      expect(compressor.calls, ['video $overLimit']);
      final outgoing = (await session.storedOutgoing(bob)).single;
      expect(outgoing.attachment!.pendingCompression, isFalse);
      expect(outgoing.attachment!.name, 'clip.mp4');
      expect(callsStarting('upload'), isEmpty);

      remote.emitStatus(const Connected());
      await idle();
      expect(remote.histories[bob], hasLength(1));
    });

    test('an app closed while compressing compresses it again', () async {
      // On disk: closing the session closes its database.
      final folder = Directory.systemTemp.createTempSync('outbox');
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File('${folder.path}/chat.sqlite');
      FakeTinodeSession link() =>
          FakeTinodeSession(chats: [chat(bob, name: 'Bob')])..loggedIn = true;
      // Closing a session closes its link too: each start gets its own.
      await session.close();
      remote = link();
      database = ChatDatabase(NativeDatabase(file));
      session = open();
      compressor.videoSteps = StreamController<double>();
      await session.sendAttachment(bob, video());
      await idle();
      await session.close();
      await compressor.videoSteps!.close();
      compressor.videoSteps = null;

      remote = link();
      database = ChatDatabase(NativeDatabase(file));
      session = open();
      await idle();

      expect(
        compressor.calls.where((c) => c.startsWith('video')),
        hasLength(2),
      );
      expect(remote.histories[bob], hasLength(1));
    });

    test('holds the messages after it in its chat', () async {
      final steps = compressor.videoSteps = StreamController<double>();
      await session.sendAttachment(bob, video());
      await session.send(bob, const PlainText('after'));
      await idle();

      expect(remote.histories[bob], isNull);

      await steps.close();
      await idle();
      expect(remote.calls.where((c) => c.startsWith('publish')), [
        'publish $bob  ',
        'publish $bob after',
      ]);
    });
  });

  group('a photo', () {
    test('is compressed to a JPEG before it is uploaded', () async {
      await session.sendAttachment(bob, photo());
      await idle();

      expect(compressor.calls, ['image ${pngBytes.length}']);
      final image = (remote.histories[bob]!.single.content as DraftyContent)
          .drafty
          .images
          .single;
      expect(image.name, 'a.jpg');
      expect(image.mimeType, 'image/jpeg');
      expect((image.width, image.height), (3, 2));
    });

    test('shows at once with a poster that outlives its compression', () async {
      final poster = Uint8List.fromList([9, 9, 9]);
      compressor.imagePosterBytes = poster;
      final queued = await session.sendAttachment(bob, photo());
      expect(queued.attachment!.poster, poster);
      expect(queued.attachment!.pendingCompression, isTrue);

      final compressed = events
          .whereType<OutgoingChanged>()
          .map((e) => e.message.attachment!)
          .where((a) => !a.pendingCompression);
      await idle();
      expect(compressed, isNotEmpty);
      expect(compressed.first.stagedId, isNot(queued.attachment!.stagedId));
      expect(compressed.first.poster, poster);
    });

    test('sends no poster: it is for its bubble only', () async {
      compressor.imagePosterBytes = Uint8List.fromList([9, 9, 9]);
      await session.sendAttachment(bob, photo());
      await idle();

      final drafty =
          (remote.histories[bob]!.single.content as DraftyContent).drafty;
      expect(drafty.images.single.bytes, isNull);
    });

    test('reports its compression without a fraction', () async {
      await session.sendAttachment(bob, photo());
      await idle();

      expect(events.whereType<CompressProgress>().map((e) => e.fraction), [
        null,
      ]);
    });

    test('a GIF keeps its motion: it goes as it is', () async {
      await session.sendAttachment(
        bob,
        pickedFile('a.gif', [1, 2], mimeType: 'image/gif', isImage: true),
      );
      await idle();

      expect(compressor.calls, isEmpty);
      expect(remote.histories[bob], hasLength(1));
    });

    test('a GIF gets no poster: its bubble shows it moving', () async {
      compressor.imagePosterBytes = Uint8List.fromList([9, 9, 9]);
      final queued = await session.sendAttachment(
        bob,
        pickedFile('a.gif', [1, 2], mimeType: 'image/gif', isImage: true),
      );

      expect(queued.attachment!.poster, isNull);
      await idle();
    });
  });

  test('a file goes as it is', () async {
    await session.sendAttachment(bob, pickedText('notes.txt', 'hello'));
    await idle();

    expect(compressor.calls, isEmpty);
    expect(remote.histories[bob], hasLength(1));
  });
}
