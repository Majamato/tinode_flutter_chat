import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'login_controller.g.dart';

/// The login form's submission: loading while a login runs, an error when
/// it failed. Only the submit button and the error text watch it.
@riverpod
class LoginController extends _$LoginController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit(String login, String password) async {
    if (state.isLoading) {
      return;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(sessionControllerProvider.notifier)
          .login(TinodeCredentials.password(login.trim(), password)),
    );
    if (ref.mounted) {
      state = result;
    }
  }
}

/// The message under the login form: the last submission's error, or why
/// the host's credentials were rejected.
@riverpod
ChatFailure? loginFailure(Ref ref) {
  final submitError = ref.watch(
    loginControllerProvider.select(
      (s) => s.hasError ? ChatFailure.of(s.error!) : null,
    ),
  );
  return submitError ??
      ref.watch(
        sessionControllerProvider.select(
          (s) => switch (s.value) {
            SessionAwaitingLogin(:final lastFailure) => lastFailure,
            _ => null,
          },
        ),
      );
}
