import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'confirm_email_controller.g.dart';

/// Confirming the user's email with the code the server mailed, by logging
/// in with it: loading while it runs, an error when it failed. Success
/// logs in, which leaves the login screens.
@riverpod
class ConfirmEmailController extends _$ConfirmEmailController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> confirm({
    required String login,
    required String password,
    required String code,
  }) async {
    if (state.isLoading || code.trim().isEmpty) {
      return;
    }
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(sessionControllerProvider.notifier)
          .login(
            TinodeCredentials.password(login.trim(), password),
            codes: {'email': code.trim()},
          ),
    );
    if (ref.mounted) {
      state = result;
    }
  }
}

/// Why the last confirmation failed, if it did; the server answers a wrong
/// code by asking for one again.
@riverpod
ChatFailure? confirmEmailFailure(Ref ref) => ref.watch(
  confirmEmailControllerProvider.select(
    (s) => switch (s.error) {
      null => null,
      CredentialsRequiredException() => ChatFailure.wrongCode,
      final error => ChatFailure.of(error),
    },
  ),
);
