import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'send_controller.g.dart';

/// Sending in one chat: loading while a message is on its way, an error
/// when the last send failed. Only the send button watches it.
@riverpod
class SendController extends _$SendController {
  @override
  AsyncValue<void> build(String topic) => const AsyncData(null);

  /// Publishes [text] as plain text. Returns whether it was sent, so the
  /// composer clears its field only then. Blank text is not sent.
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return false;
    state = const AsyncLoading();

    try {
      final content = PlainText(trimmed);
      final session = ref.read(activeSessionProvider);
      if (session == null) throw const ConnectionLostException();

      final ack = await session.publish(topic, content);
      if (!ref.mounted) return true;

      ref.read(chatControllerProvider(topic).notifier).addOwn(ack, content);
      state = const AsyncData(null);
      return true;
    } on Object catch (e, stackTrace) {
      if (ref.mounted) state = AsyncError(e, stackTrace);
      return false;
    }
  }
}
