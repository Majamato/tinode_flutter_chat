import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Where a password reset stands: asking for the code by email, then
/// setting the new password with it.
final class PasswordResetState with ValueObject {
  const PasswordResetState({
    this.email,
    this.busy = false,
    this.failure,
    this.done = false,
  });

  /// The address the code went to; null until one was asked for.
  final String? email;

  /// A request is on its way to the server.
  final bool busy;

  /// Why the last request failed.
  final ChatFailure? failure;

  /// The new password is set.
  final bool done;

  bool get codeSent => email != null;

  PasswordResetState started() =>
      PasswordResetState(email: email, busy: true, done: done);

  PasswordResetState codeSentTo(String email) =>
      PasswordResetState(email: email);

  PasswordResetState failed(ChatFailure failure) =>
      PasswordResetState(email: email, failure: failure);

  PasswordResetState finished() => PasswordResetState(email: email, done: true);

  @override
  List<Object?> get props => [email, busy, failure, done];
}
