import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/offline/data/cached_tinode_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  late FakeTinodeSession remote;
  late MemoryFileStore files;
  late CachedTinodeSession session;

  CachedTinodeSession open() {
    final session = CachedTinodeSession(
      remote,
      ChatStore(ChatDatabase(NativeDatabase.memory())),
      userId: alice,
      files: files,
    );
    addTearDown(session.close);
    return session;
  }

  setUp(() {
    remote = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob'),
        chat(carol, name: 'Carol'),
      ],
    )..loggedIn = true;
    files = MemoryFileStore();
    session = open();
  });

  /// Lets the uploader and the drain run to rest.
  Future<void> idle() async {
    for (var i = 0; i < 40; i++) {
      await settle();
    }
  }

  Iterable<String> callsStarting(String prefix) =>
      remote.calls.where((c) => c.startsWith(prefix));

  PickedFile notes() => pickedText('notes.txt', 'hello');

  test('uploads the file, then publishes the message with its ref', () async {
    await session.sendAttachment(bob, notes(), caption: ' read me ');
    await idle();

    expect(
      remote.calls,
      containsAllInOrder(['upload notes.txt', 'publish $bob read me']),
    );
    final sent = remote.histories[bob]!.single;
    final drafty = (sent.content as DraftyContent).drafty;
    final file = drafty.files.single;
    expect(file.ref, '/v0/file/s/fake1.txt');
    expect(file.name, 'notes.txt');
    expect(file.size, 5);
    expect(file.mimeType, 'text/plain');
    expect(drafty.caption, 'read me');
    expect(await session.storedOutgoing(bob), isEmpty);
    // The sender never downloads their own file.
    expect(files.isCached(remote.resolveFile(file.ref!)!), isTrue);
    expect(files.stagedIds, isEmpty);
    expect(await session.cachedFile(file.ref!), isNotNull);
  });

  test('an image is sent as one, with its size read from the file', () async {
    await session.sendAttachment(
      bob,
      pickedFile('a.png', pngBytes, mimeType: 'image/png', isImage: true),
    );
    await idle();

    final drafty =
        (remote.histories[bob]!.single.content as DraftyContent).drafty;
    final image = drafty.images.single;
    expect((image.width, image.height), (3, 2));
    expect(image.ref, '/v0/file/s/fake1.png');
  });

  test('reports upload progress', () async {
    final progress = <UploadProgress>[];
    session.outbox.listen((event) {
      if (event is UploadProgress) {
        progress.add(event);
      }
    });
    remote.uploadChunk = 2;

    await session.sendAttachment(bob, notes());
    await idle();

    expect(progress, isNotEmpty);
    expect(progress.first.topic, bob);
    expect(progress.last.sent, 5);
    expect(progress.last.fraction, 1);
  });

  test('a drop after the upload does not upload it again', () async {
    remote.failPublish = const ConnectionClosedException('dropped');
    await session.sendAttachment(bob, notes());
    await idle();
    expect(callsStarting('upload'), hasLength(1));
    expect(remote.histories[bob], isNull);

    remote
      ..emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero))
      ..emitStatus(const Connected());
    await idle();

    expect(callsStarting('upload'), hasLength(1));
    expect(remote.histories[bob], hasLength(1));
  });

  test('an expired ref is uploaded again', () async {
    var now = DateTime.utc(2026, 10, 9, 12);
    await withClock(Clock(() => now), () async {
      final session = open();
      remote.failPublish = const ConnectionClosedException('dropped');
      await session.sendAttachment(bob, notes());
      await idle();
      expect(callsStarting('upload'), hasLength(1));

      now = now.add(const Duration(minutes: 2));
      remote
        ..emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero))
        ..emitStatus(const Connected());
      await idle();

      expect(callsStarting('upload'), hasLength(2));
      final drafty =
          (remote.histories[bob]!.single.content as DraftyContent).drafty;
      expect(drafty.files.single.ref, '/v0/file/s/fake2.txt');
    });
  });

  test('its chat waits for the upload; other chats do not', () async {
    final hold = remote.holdUpload = Completer<void>();
    await session.sendAttachment(bob, notes());
    await session.send(bob, const PlainText('after'));
    await session.send(carol, const PlainText('meanwhile'));
    await idle();

    expect(remote.calls, contains('publish $carol meanwhile'));
    expect(callsStarting('publish $bob'), isEmpty);

    hold.complete();
    await idle();

    expect(
      [for (final m in remote.histories[bob]!) m.content.text],
      ['', 'after'],
    );
  });

  test(
    'a drop during the upload aborts it; it starts over on connect',
    () async {
      remote.holdUpload = Completer<void>();
      await session.sendAttachment(bob, notes());
      await idle();

      remote.emitStatus(const Reconnecting(attempt: 1, retryIn: Duration.zero));
      await idle();
      expect(remote.histories[bob], isNull);
      expect(
        (await session.storedOutgoing(bob)).single.status,
        OutgoingStatus.queued,
      );

      remote
        ..holdUpload = null
        ..emitStatus(const Connected());
      await idle();

      expect(callsStarting('upload'), hasLength(2));
      expect(remote.histories[bob], hasLength(1));
    },
  );

  test('a file the server finds too large fails the message', () async {
    remote.failUpload = const ServerException(413, 'too large');
    await session.sendAttachment(bob, notes());
    await idle();

    final failed = (await session.storedOutgoing(bob)).single;
    expect(failed.status, OutgoingStatus.failed);
    expect(failed.failure, ChatFailure.tooLarge);
    expect(callsStarting('publish'), isEmpty);
    // Kept for a retry.
    expect(files.stagedIds, hasLength(1));
  });

  test('a network failure is tried again after a pause', () async {
    remote.failUpload = ServerUnreachableException(Exception('no route'));
    final events = <OutboxEvent>[];
    session.outbox.listen(events.add);
    await session.sendAttachment(bob, notes());
    await idle();

    // Not failed: the first retry comes within two seconds.
    expect(
      events.whereType<OutgoingChanged>().map((e) => e.message.status),
      isNot(contains(OutgoingStatus.failed)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    await idle();

    expect(callsStarting('upload'), hasLength(2));
    expect(remote.histories[bob], hasLength(1));
    expect(await session.storedOutgoing(bob), isEmpty);
  });

  test('discarding it during the upload cancels the upload', () async {
    remote.holdUpload = Completer<void>();
    final events = <OutboxEvent>[];
    session.outbox.listen(events.add);
    final sent = await session.sendAttachment(bob, notes());
    await idle();

    await session.discard(sent.clientId);
    await idle();

    expect(events.last, OutgoingDiscarded(bob, sent.clientId));
    expect(await session.storedOutgoing(bob), isEmpty);
    expect(files.stagedIds, isEmpty);
    expect(callsStarting('publish'), isEmpty);
  });

  test('a failed upload can be retried', () async {
    remote.failUpload = const ServerException(403, 'denied');
    final sent = await session.sendAttachment(bob, notes());
    await idle();
    expect(
      (await session.storedOutgoing(bob)).single.status,
      OutgoingStatus.failed,
    );

    await session.retry(sent.clientId);
    await idle();

    expect(remote.histories[bob], hasLength(1));
  });

  test('a file over the server limit is refused before queuing', () async {
    remote.serverInfo = const ServerInfo(version: '0.25', maxFileUploadSize: 4);

    await expectLater(
      session.sendAttachment(bob, notes()),
      throwsA(isA<FileTooLargeException>().having((e) => e.limit, 'limit', 4)),
    );
    expect(await session.storedOutgoing(bob), isEmpty);
    expect(files.stagedIds, isEmpty);
  });

  group('received files', () {
    const ref = '/v0/file/s/x.txt';

    setUp(() => remote.files[ref] = pngBytes);

    test(
      'download once for everyone asking, then come from the cache',
      () async {
        final progress = <int>[];
        final both = await Future.wait([
          session.fetchFile(
            ref,
            onProgress: (received, _) => progress.add(received),
          ),
          session.fetchFile(ref),
        ]);

        expect(both[0], both[1]);
        expect(both[0].length, pngBytes.length);
        expect(progress.last, pngBytes.length);
        expect(callsStarting('download'), hasLength(1));

        expect(await session.cachedFile(ref), both[0]);
        await session.fetchFile(ref);
        expect(callsStarting('download'), hasLength(1));
      },
    );

    test('a failed download is not cached', () async {
      remote.failDownload = ServerUnreachableException(Exception('offline'));
      await expectLater(
        session.fetchFile(ref),
        throwsA(isA<ServerUnreachableException>()),
      );
      expect(await session.cachedFile(ref), isNull);

      expect((await session.fetchFile(ref)).length, pngBytes.length);
    });
  });
}
