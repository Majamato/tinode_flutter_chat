import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet_action.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Where to pick an attachment from, as rows: Photos (Gallery off Apple's
/// platforms), Camera (where the device has one) and, with [files], File.
/// Pops with the chosen [AttachmentSource]. Watches whether there is a
/// camera.
///
/// With [files] it is the chat's menu: the first row picks a photo or a
/// video ([AttachmentSource.media]). Without, it picks a profile photo
/// ([AttachmentSource.gallery]).
class AttachSheet extends ConsumerWidget {
  const AttachSheet({this.files = true, super.key});

  /// Whether to offer videos and any file, not just photos (off for a
  /// profile photo).
  final bool files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final hasCamera = ref.watch(cameraAvailableProvider);
    final apple = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    return ChatSheet(
      children: [
        ChatSheetAction(
          icon: icons.gallery,
          label: apple ? strings.attachPhotos : strings.attachGallery,
          subtitle: files ? strings.attachMediaSubtitle : null,
          onTap: () => _choose(
            context,
            files ? AttachmentSource.media : AttachmentSource.gallery,
          ),
        ),
        if (hasCamera)
          ChatSheetAction(
            icon: icons.camera,
            label: strings.attachCamera,
            subtitle: files ? strings.attachCameraSubtitle : null,
            onTap: () => _choose(context, AttachmentSource.camera),
          ),
        if (files)
          ChatSheetAction(
            icon: icons.file,
            label: strings.attachFile,
            onTap: () => _choose(context, AttachmentSource.file),
          ),
      ],
    );
  }

  void _choose(BuildContext context, AttachmentSource source) =>
      Navigator.of(context).pop(source);
}
