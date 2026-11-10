@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/application/sent_stand_ins.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';

import '../support/fake_attachment_picker.dart';
import '../support/fake_media_compressor.dart';

// Runs against ../tinode-tests (sample users alice and bob):
//   flutter test --tags integration --run-skipped --concurrency=1
final config = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K',
  userAgent: 'tinode_flutter_chat-test/0.1',
);

Future<(ProviderContainer, String)> loginAs(String user) async {
  final container = createTinodeContainer(
    config: config,
    credentials: TinodeCredentials.password(user, '${user}123'),
    storeOpener: MemoryChatStoreOpener(),
    fileStoreOpener: MemoryFileStoreOpener(),
    // The device's encoders aren't there: photos and videos go as they are.
    mediaCompressor: FakeMediaCompressor(poster: pngBytes),
  );
  addTearDown(container.dispose);
  container
    ..listen(sessionControllerProvider, (_, _) {})
    ..listen(chatListControllerProvider, (_, _) {});
  final state = await container.read(sessionControllerProvider.future);
  expect(state, isA<SessionLoggedIn>());
  return (container, container.read(currentUserIdProvider)!);
}

/// Polls [condition] until it holds, failing after [timeout].
Future<void> eventually(
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test(
    'an image alice sends reaches bob and downloads byte for byte',
    () async {
      final (alice, aliceId) = await loginAs('alice');
      final (bob, bobId) = await loginAs('bob');
      alice.listen(chatControllerProvider(bobId), (_, _) {});
      bob.listen(chatControllerProvider(aliceId), (_, _) {});
      await eventually(
        'both chats loaded',
        () =>
            alice.read(chatControllerProvider(bobId)).lastSeq != null &&
            bob.read(chatControllerProvider(aliceId)).lastSeq != null,
      );
      final caption = 'photo ${DateTime.now().toIso8601String()}';

      alice.listen(sendControllerProvider(bobId), (_, _) {});
      final queued = await alice
          .read(sendControllerProvider(bobId).notifier)
          .sendAttachment(
            pickedFile(
              'red.png',
              pngBytes,
              mimeType: 'image/png',
              isImage: true,
            ),
            caption: caption,
          );
      expect(queued, isTrue);

      ImageAttachment? received;
      await eventually("the image on bob's side", () {
        final chat = bob.read(chatControllerProvider(aliceId));
        final last = chat.bySeq[chat.lastSeq];
        if (last?.caption != caption) {
          return false;
        }
        received = last!.attachments.whereType<ImageAttachment>().firstOrNull;
        return received != null;
      });
      expect((received!.width, received!.height), (3, 2));
      expect(received!.ref, startsWith('/v0/file/s/'));

      final session = bob.read(activeSessionProvider)!;
      final file = await session.fetchFile(received!.ref!);
      expect(file.bytes, pngBytes);
      // Through the provider too, from bob's cache now.
      expect(
        (await bob.read(attachmentFileProvider(received!.ref!).future)).length,
        pngBytes.length,
      );
      expect(base64.encode(file.bytes!), base64.encode(pngBytes));
    },
  );
  test("a sent photo finds its outgoing bubble's stand-in at once, "
      'whether the echo or the ack comes first', () async {
    final (alice, aliceId) = await loginAs('alice');
    final (_, bobId) = await loginAs('bob');
    final standIns = alice.read(sentStandInsProvider);
    final caption = 'stand-in ${DateTime.now().toIso8601String()}';
    final poster = LocalFile.inMemory(pngBytes);

    // As the outgoing bubble does: leave the picture by client ID. Then,
    // the first time the chat shows the sent message (its numbered copy),
    // note whether its bubble would find the stand-in.
    String? outgoingId;
    LocalFile? foundOnFirstSight;
    var sentSeen = false;
    alice.listen(chatControllerProvider(bobId), (_, chat) {
      for (final id in chat.outgoingIds) {
        final message = chat.outgoingById[id]!;
        if (message.attachment?.caption == caption) {
          outgoingId = id;
          standIns.leave(id, poster);
        }
      }
      if (!sentSeen && chat.bySeq[chat.lastSeq]?.caption == caption) {
        sentSeen = true;
        final clientId = chat.bySeq[chat.lastSeq]!.clientId;
        foundOnFirstSight = clientId == null ? null : standIns[clientId];
      }
    });
    await eventually(
      "alice's chat loaded",
      () => alice.read(chatControllerProvider(bobId)).lastSeq != null,
    );
    // Which came first: the chat showing the sent message (the echo, or
    // the ack) or the outbox reporting it sent (the ack's handling).
    final order = <String>[];
    final session = alice.read(activeSessionProvider)!;
    final events = session.outbox.listen((event) {
      if (event is OutgoingSent) {
        order.add(sentSeen ? 'chat, then outbox' : 'outbox, then chat');
      }
    });
    addTearDown(events.cancel);

    alice.listen(sendControllerProvider(bobId), (_, _) {});
    await alice
        .read(sendControllerProvider(bobId).notifier)
        .sendAttachment(
          pickedFile('red.png', pngBytes, mimeType: 'image/png', isImage: true),
          caption: caption,
        );
    await eventually("the sent message in alice's chat", () => sentSeen);
    await eventually('the outbox reporting it sent', () => order.isNotEmpty);

    // The order is the server's to choose: the log says which this run
    // went through.
    // ignore: avoid_print
    print('Real server order: ${order.first}; client ID $outgoingId');
    expect(outgoingId, isNotNull);
    expect(foundOnFirstSight, same(poster));
    expect(aliceId, isNotEmpty);
  });

  test('a voice message alice records reaches bob with its duration and '
      'waveform, and downloads byte for byte', () async {
    final (alice, aliceId) = await loginAs('alice');
    final (bob, bobId) = await loginAs('bob');
    alice.listen(chatControllerProvider(bobId), (_, _) {});
    bob.listen(chatControllerProvider(aliceId), (_, _) {});
    await eventually(
      'both chats loaded',
      () =>
          alice.read(chatControllerProvider(bobId)).lastSeq != null &&
          bob.read(chatControllerProvider(aliceId)).lastSeq != null,
    );
    // A unique length tells this run's message from earlier ones.
    final duration = Duration(
      milliseconds: 2000 + DateTime.now().millisecondsSinceEpoch % 100000,
    );
    final waveform = [for (var i = 0; i < 96; i++) (i * 7) % 101];
    // Not real AAC: the server stores whatever it is given.
    final recording = Uint8List.fromList(
      List.generate(4096, (i) => (i * 31) % 256),
    );

    alice.listen(sendControllerProvider(bobId), (_, _) {});
    final queued = await alice
        .read(sendControllerProvider(bobId).notifier)
        .sendAttachment(
          pickedFile(
            'voice.m4a',
            recording,
            mimeType: 'audio/mp4',
          ).withVoice(VoiceNote(duration: duration, waveform: waveform)),
        );
    expect(queued, isTrue);

    VoiceAttachment? received;
    await eventually("the voice message on bob's side", () {
      final chat = bob.read(chatControllerProvider(aliceId));
      final voice = chat.bySeq[chat.lastSeq]?.voice;
      if (voice?.duration != duration) {
        return false;
      }
      received = voice;
      return true;
    });
    expect(received!.mimeType, 'audio/mp4');
    expect(received!.waveform, waveform);
    expect(received!.ref, startsWith('/v0/file/s/'));

    final session = bob.read(activeSessionProvider)!;
    final file = await session.fetchFile(received!.ref!);
    expect(file.bytes, recording);
  });

  test('a video alice sends reaches bob with its poster, size and length, '
      'and downloads byte for byte', () async {
    final (alice, aliceId) = await loginAs('alice');
    final (bob, bobId) = await loginAs('bob');
    alice.listen(chatControllerProvider(bobId), (_, _) {});
    bob.listen(chatControllerProvider(aliceId), (_, _) {});
    await eventually(
      'both chats loaded',
      () =>
          alice.read(chatControllerProvider(bobId)).lastSeq != null &&
          bob.read(chatControllerProvider(aliceId)).lastSeq != null,
    );
    final caption = 'video ${DateTime.now().toIso8601String()}';
    // Not real MP4: the server stores whatever it is given.
    final clip = Uint8List.fromList(List.generate(8192, (i) => (i * 13) % 256));

    alice.listen(sendControllerProvider(bobId), (_, _) {});
    final queued = await alice
        .read(sendControllerProvider(bobId).notifier)
        .sendAttachment(
          pickedFile(
            'clip.mov',
            clip,
            mimeType: 'video/quicktime',
            isVideo: true,
          ),
          caption: caption,
        );
    expect(queued, isTrue);

    VideoAttachment? received;
    await eventually("the video on bob's side", () {
      final chat = bob.read(chatControllerProvider(aliceId));
      final last = chat.bySeq[chat.lastSeq];
      if (last?.caption != caption) {
        return false;
      }
      received = last!.attachments.whereType<VideoAttachment>().firstOrNull;
      return received != null;
    });
    // Within the limit: it goes as it is.
    expect(received!.name, 'clip.mov');
    expect(received!.mimeType, 'video/quicktime');
    expect((received!.width, received!.height), (1280, 720));
    expect(received!.duration, const Duration(seconds: 10));
    expect(received!.poster, pngBytes);
    expect(received!.ref, startsWith('/v0/file/s/'));

    final session = bob.read(activeSessionProvider)!;
    final file = await session.fetchFile(received!.ref!);
    expect(file.bytes, clip);
  });
}
