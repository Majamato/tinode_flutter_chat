import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attach_sheet.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_photo_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';

/// The user's avatar with a button that picks a new photo, from the
/// gallery or, where the device has one, the camera. Watches the profile's
/// photo and initials, and whether a new photo is on its way.
class ProfilePhotoButton extends ConsumerWidget {
  const ProfilePhotoButton({super.key});

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(profilePhotoControllerProvider.notifier);
    final source = ref.read(attachmentPickerProvider).hasCamera
        ? await showChatSheet<AttachmentSource>(
            context,
            builder: (_) => const AttachSheet(files: false),
          )
        : AttachmentSource.gallery;
    if (source != null) {
      await controller.change(source);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (photo, initials) = ref.watch(
      profileControllerProvider.select(
        (s) => (s.value?.photo, s.value?.initials ?? ''),
      ),
    );
    final busy = ref.watch(
      profilePhotoControllerProvider.select((s) => s.isLoading),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        ProfileAvatar(initials: initials, photo: photo, radius: 48),
        if (busy) const CircularProgressIndicator(),
        Positioned(
          right: 0,
          bottom: 0,
          child: IconButton.filledTonal(
            tooltip: TinodeChatStrings.of(context).changePhoto,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            onPressed: busy ? null : () => unawaited(_change(context, ref)),
            icon: Icon(TinodeChatIcons.of(context).camera),
          ),
        ),
      ],
    );
  }
}
