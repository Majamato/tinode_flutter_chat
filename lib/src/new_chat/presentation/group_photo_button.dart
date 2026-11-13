import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attach_sheet.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_photo_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The new group's photo: a circle with a camera until one is picked, then
/// the photo. A tap picks one from the gallery or, where the device has
/// one, the camera. Watches the picked photo.
class GroupPhotoButton extends ConsumerWidget {
  const GroupPhotoButton({super.key});

  static const _size = 64.0;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(newGroupPhotoControllerProvider.notifier);
    final source = ref.read(attachmentPickerProvider).hasCamera
        ? await showChatSheet<AttachmentSource>(
            context,
            builder: (_) => const AttachSheet(files: false),
          )
        : AttachmentSource.gallery;
    if (source != null) {
      await controller.pick(source);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (preview, busy) = ref.watch(
      newGroupPhotoControllerProvider.select(
        (s) => (s.value?.preview, s.isLoading),
      ),
    );
    final colors = Theme.of(context).colorScheme;
    final label = TinodeChatStrings.of(context).groupPhoto;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: colors.surface,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: busy ? null : () => unawaited(_pick(context, ref)),
            child: SizedBox.square(
              dimension: _size,
              child: switch ((preview, busy)) {
                (_, true) => const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                (final preview?, _) => Image.memory(
                  preview,
                  fit: BoxFit.cover,
                  cacheWidth: (_size * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                ),
                _ => Icon(
                  TinodeChatIcons.of(context).camera,
                  color: TinodeChatTheme.of(context).linkColor,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
