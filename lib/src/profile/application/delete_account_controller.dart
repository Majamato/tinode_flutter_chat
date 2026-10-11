import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'delete_account_controller.g.dart';

/// Deleting the user's account: loading while it runs, an error when it
/// failed. Success ends the session, which shows the login screen.
@riverpod
class DeleteAccountController extends _$DeleteAccountController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> delete() async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(sessionControllerProvider.notifier).deleteAccount(),
    );
    if (ref.mounted) {
      state = result;
    }
  }
}

/// Why deleting the account failed, if it did.
@riverpod
ChatFailure? deleteAccountFailure(Ref ref) => ref.watch(
  deleteAccountControllerProvider.select(
    (s) => s.hasError ? ChatFailure.of(s.error!) : null,
  ),
);
