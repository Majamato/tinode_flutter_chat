import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/domain/presence_visibility.dart';

part 'presence_visibility_controller.g.dart';

/// Whether others see when the user is online and was last seen: "Show my
/// online status". Saved in the user's profile (see `PresenceVisibility`),
/// so it follows them to every device. Loading while it saves, an error
/// when that failed.
@riverpod
class PresenceVisibilityController extends _$PresenceVisibilityController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Shows or hides the user's presence; returns whether it was saved.
  Future<bool> set({required bool shown}) async {
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
      final updated = current.profile.withPresenceHidden(hidden: !shown);
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

/// Whether others see the user's presence, from their profile; null while
/// it can't be read, e.g. offline.
@riverpod
bool? myPresenceShown(Ref ref) => ref.watch(
  profileControllerProvider.select(
    (profile) => switch (profile.value) {
      final profile? => !profile.profile.hidesPresence,
      null => null,
    },
  ),
);
