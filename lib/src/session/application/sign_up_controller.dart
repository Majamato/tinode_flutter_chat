import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'sign_up_controller.g.dart';

/// The sign-up form's submission: loading while it runs, an error when it
/// failed. Success logs the new user in, which leaves the login screens.
@riverpod
class SignUpController extends _$SignUpController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// A blank [email] gives none. Returns true when the account was made
  /// but its email waits for the mailed code: the form then asks for it.
  Future<bool> submit({
    required String login,
    required String password,
    required String name,
    String email = '',
  }) async {
    if (state.isLoading) {
      return false;
    }

    state = const AsyncLoading();
    final address = email.trim();
    final result = await AsyncValue.guard(
      () => ref
          .read(sessionControllerProvider.notifier)
          .signUp(
            login: login.trim(),
            password: password,
            name: name.trim(),
            email: address.isEmpty ? null : address,
          ),
    );
    final confirm = result.error is CredentialsRequiredException;
    if (ref.mounted) {
      state = confirm ? const AsyncData(null) : result;
    }
    return confirm;
  }
}

/// Why the last sign-up failed, if it did. The server marks a taken login
/// (`what: auth`), so another 409 is the email.
@riverpod
ChatFailure? signUpFailure(Ref ref) => ref.watch(
  signUpControllerProvider.select(
    (s) => s.hasError ? ChatFailure.ofAccount(s.error!, withEmail: true) : null,
  ),
);

/// Whether the login screen offers to sign up, as the host chose.
@riverpod
bool signUpOffered(Ref ref) =>
    ref.watch(tinodeChatFeaturesProvider.select((features) => features.signUp));

/// Whether the login screen offers to reset a forgotten password: as the
/// host chose, by default where the server requires an email, since it
/// then sends email.
@riverpod
bool passwordResetOffered(Ref ref) {
  final features = ref.watch(tinodeChatFeaturesProvider);
  final required = ref.watch(
    sessionControllerProvider.select(
      (s) => switch (s.value) {
        SessionAwaitingLogin(:final session) =>
          session.serverInfo.requiredCredentials,
        _ => const <String>[],
      },
    ),
  );
  return features.offersPasswordReset(required);
}

/// Whether the server wants an email at sign-up, which it then has the
/// user confirm with a mailed code.
@riverpod
bool signUpNeedsEmail(Ref ref) => ref.watch(
  sessionControllerProvider.select(
    (s) => switch (s.value) {
      SessionAwaitingLogin(:final session) =>
        session.serverInfo.requiredCredentials.contains('email'),
      _ => false,
    },
  ),
);
