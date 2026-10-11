import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'change_password_controller.g.dart';

/// Changing the password, and maybe the login: loading while it runs, an
/// error when it failed, data once done. Tokens already handed out stay
/// valid, so the session goes on.
@riverpod
class ChangePasswordController extends _$ChangePasswordController {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  /// A blank [login] keeps the current one.
  Future<void> submit({required String password, String login = ''}) async {
    if (state.isLoading || password.isEmpty) {
      return;
    }
    state = const AsyncLoading();
    final newLogin = login.trim();
    final result = await AsyncValue.guard(() async {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      await session.changePassword(
        password,
        login: newLogin.isEmpty ? null : newLogin,
      );
      return true;
    });
    if (ref.mounted) {
      state = result;
    }
  }
}

/// Why the last change failed, if it did.
@riverpod
ChatFailure? changePasswordFailure(Ref ref) => ref.watch(
  changePasswordControllerProvider.select(
    (s) => s.hasError ? ChatFailure.ofAccount(s.error!) : null,
  ),
);
