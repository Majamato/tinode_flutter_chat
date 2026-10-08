import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'send_controller.g.dart';

/// Sending in one chat: loading while a message goes into the outbox, an
/// error when that failed. Only the send button watches it.
///
/// The outbox sends it when the link allows; the chat shows it meanwhile,
/// and marks it failed if the server refuses it.
@riverpod
class SendController extends _$SendController {
  @override
  AsyncValue<void> build(String topic) => const AsyncData(null);

  /// Queues [text] as plain text. Returns whether it was queued, so the
  /// composer clears its field only then. Blank text is not sent.
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) {
      return false;
    }
    state = const AsyncLoading();

    try {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      await session.send(topic, PlainText(trimmed));
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return true;
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return false;
    }
  }
}
