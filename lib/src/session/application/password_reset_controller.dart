import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/password_reset_state.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'password_reset_controller.g.dart';

/// A forgotten password, reset from the login screens: [request] emails a
/// code, [reset] sets the new password with it. Neither logs in.
@riverpod
class PasswordResetController extends _$PasswordResetController {
  @override
  PasswordResetState build() => const PasswordResetState();

  /// Asks the server to email a code to [email]. A code sent earlier that
  /// is still valid counts: the server sends no new one then (409).
  Future<void> request(String email) async {
    final address = email.trim();
    await _run((session) async {
      try {
        await session.requestPasswordReset(address);
      } on ServerException catch (e) {
        if (e.code != 409) {
          rethrow;
        }
      }
      return state.codeSentTo(address);
    });
  }

  /// Sets [password] with the emailed [code].
  Future<void> reset({required String code, required String password}) async {
    final email = state.email;
    if (email == null) {
      throw StateError('No code was asked for.');
    }
    await _run((session) async {
      await session.resetPassword(
        email: email,
        code: code.trim(),
        password: password,
      );
      return state.finished();
    });
  }

  Future<void> _run(
    Future<PasswordResetState> Function(TinodeSession session) step,
  ) async {
    if (state.busy) {
      return;
    }
    final session = ref.read(sessionControllerProvider).value?.session;
    if (session == null) {
      state = state.failed(ChatFailure.connectionLost);
      return;
    }
    state = state.started();
    try {
      final next = await step(session);
      if (ref.mounted) {
        state = next;
      }
    } on Object catch (e) {
      if (ref.mounted) {
        state = state.failed(
          e is ServerException && e.code == 401
              ? ChatFailure.wrongCode
              : ChatFailure.of(e),
        );
      }
    }
  }
}
