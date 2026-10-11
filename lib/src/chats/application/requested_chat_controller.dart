import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'requested_chat_controller.g.dart';

/// A chat the host asked to open, e.g. from a tapped notification, until
/// the chat navigator opens it. It waits while nobody is logged in.
@Riverpod(keepAlive: true)
class RequestedChatController extends _$RequestedChatController {
  @override
  String? build() => null;

  /// Asks to open [topic]; a later request replaces one not yet opened.
  // A setter would hide that this notifies the navigator.
  // ignore: use_setters_to_change_properties
  void request(String topic) => state = topic;

  /// The navigator opened the chat.
  void opened() => state = null;
}
