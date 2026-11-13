import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/group_photo.dart';

part 'new_group_photo_controller.g.dart';

/// The photo picked for a new group, from [AttachmentSource.gallery] or
/// the camera: loading while it is read, an error when picking failed.
/// Nothing is uploaded until the group is created.
@riverpod
class NewGroupPhotoController extends _$NewGroupPhotoController {
  @override
  AsyncValue<GroupPhoto?> build() => const AsyncData(null);

  /// Keeps the photo already picked when the user cancels the picker or
  /// picks no image.
  Future<void> pick(AttachmentSource source) async {
    if (state.isLoading) {
      return;
    }
    final previous = state.value;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final picked = await ref.read(attachmentPickerProvider).pick(source);
      if (picked == null || !picked.isImage) {
        return previous;
      }
      final bytes = BytesBuilder(copy: false);
      await picked.openRead().forEach(bytes.add);
      return GroupPhoto(file: picked, preview: bytes.takeBytes());
    });
    if (ref.mounted) {
      state = result;
    }
  }
}
