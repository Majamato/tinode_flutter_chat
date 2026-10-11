import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'profile_save_controller.g.dart';

/// Saving the profile's name and note: loading while it runs, an error
/// when it failed. Only the save button and the error text watch it.
@riverpod
class ProfileSaveController extends _$ProfileSaveController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns whether it was saved.
  Future<bool> save({required String name, required String note}) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      final current = await ref.read(profileControllerProvider.future);
      final updated = current.profile.copyWith(
        name: name.trim(),
        note: note.trim(),
      );
      await session.updateProfile(updated);
      if (ref.mounted) {
        ref.read(profileControllerProvider.notifier).saved(updated);
      }
    });
    if (ref.mounted) {
      state = result;
    }
    return !result.hasError;
  }
}

/// Why saving the profile or its photo failed, if it did.
@riverpod
ChatFailure? profileSaveFailure(Ref ref) => ref.watch(
  profileSaveControllerProvider.select(
    (s) => s.hasError ? ChatFailure.of(s.error!) : null,
  ),
);
