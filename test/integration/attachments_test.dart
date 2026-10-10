@Tags(['integration'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import '../support/fake_attachment_picker.dart';

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
}
