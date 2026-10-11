import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/profile/domain/my_profile.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'profile_photo_controller.g.dart';

/// A new profile photo: picked from [AttachmentSource.gallery] or the
/// camera, uploaded, then set in the profile by ref. Loading while it runs,
/// an error when it failed. Only the photo button watches it.
@riverpod
class ProfilePhotoController extends _$ProfilePhotoController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Does nothing when the user cancels the picker or picks no image.
  Future<void> change(AttachmentSource source) async {
    if (state.isLoading) {
      return;
    }
    final PickedFile? picked;
    try {
      picked = await ref.read(attachmentPickerProvider).pick(source);
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return;
    }
    if (picked == null || !picked.isImage || !ref.mounted) {
      return;
    }
    final file = picked;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      final current = await ref.read(profileControllerProvider.future);
      final upload = await session.upload(
        file.openRead,
        length: file.length,
        filename: file.name,
        mimeType: file.mimeType,
      );
      final updated = current.profile.copyWith(
        photo: ProfilePhoto(
          type: MyProfile.photoType(file.mimeType),
          ref: upload.ref,
        ),
      );
      await session.updateProfile(updated);
      if (ref.mounted) {
        ref.read(profileControllerProvider.notifier).saved(updated);
      }
    });
    if (ref.mounted) {
      state = result;
    }
  }
}

/// Why the last photo change failed, if it did.
@riverpod
ChatFailure? profilePhotoFailure(Ref ref) => ref.watch(
  profilePhotoControllerProvider.select(
    (s) => s.hasError ? ChatFailure.of(s.error!) : null,
  ),
);
