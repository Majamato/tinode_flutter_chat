import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';
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
    compressor = FakeMediaCompressor(poster: Uint8List.fromList([7, 7, 7]));
    events = [];
    session = open();
  });

  /// Lets the compressor, the uploader and the drain run to rest.
  Future<void> idle() async {
    for (var i = 0; i < 40; i++) {
      await settle();
    }
  }

  PickedFile video({int length = 1000}) => pickedFile(
    'clip.mov',
    List.filled(length, 1),
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

      expect(compressor.calls, ['video 1000']);
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

    test('too long to fit is refused before it is queued', () async {
      compressor.info = const VideoInfo(duration: Duration(minutes: 3));

      await expectLater(
        session.sendAttachment(bob, video(length: 50 * 1024 * 1024)),
        throwsA(
          isA<VideoTooLongException>().having(
            (e) => e.max,
            'max',
            limits.maxVideoDuration,
          ),
        ),
      );
      expect(await session.storedOutgoing(bob), isEmpty);
      expect(files.stagedIds, isEmpty);
      expect(compressor.calls, isEmpty);
    });

    test('small enough as it is passes the estimate, however long', () async {
      compressor.info = const VideoInfo(duration: Duration(minutes: 3));

      await session.sendAttachment(bob, video());
      await idle();

      expect(remote.histories[bob], hasLength(1));
    });

    test('still too large once compressed is not sent', () async {
      compressor.videoLength = limits.maxVideoBytes + 1;

      await session.sendAttachment(bob, video());
      await idle();

      final outgoing = (await session.storedOutgoing(bob)).single;
      expect(outgoing.status, OutgoingStatus.failed);
      expect(outgoing.failure, ChatFailure.tooLarge);
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

      expect(compressor.calls, ['video 1000', 'cancel']);
      expect(await session.storedOutgoing(bob), isEmpty);
      expect(files.stagedIds, isEmpty);
      expect(callsStarting('upload'), isEmpty);
    });

    test('compresses offline, and uploads once connected', () async {
      remote.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));
      await session.sendAttachment(bob, video());
      await idle();

      expect(compressor.calls, ['video 1000']);
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
