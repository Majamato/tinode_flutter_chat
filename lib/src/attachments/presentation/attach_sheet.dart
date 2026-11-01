import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet_action.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Where to pick an attachment from, as rows: Photo, Camera (where the
/// device has one) and, with [files], File. Pops with the chosen
/// [AttachmentSource]. Watches whether there is a camera.
class AttachSheet extends ConsumerWidget {
  const AttachSheet({this.files = true, super.key});

  /// Whether to offer any file, not just photos (off for a profile photo).
  final bool files;

  /// The rows' tints, from `senderNameColors`: blue, pink and purple.
  static const _photoTint = 4;
  static const _cameraTint = 1;
  static const _fileTint = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final chat = TinodeChatTheme.of(context);
    final hasCamera = ref.watch(cameraAvailableProvider);

    return ChatSheet(
      children: [
        ChatSheetAction(
          icon: icons.photo,
          label: strings.attachPhoto,
          tint: chat.senderNameColor(_photoTint),
          onTap: () => _choose(context, AttachmentSource.gallery),
        ),
        if (hasCamera)
          ChatSheetAction(
            icon: icons.camera,
            label: strings.attachCamera,
            tint: chat.senderNameColor(_cameraTint),
            onTap: () => _choose(context, AttachmentSource.camera),
          ),
        if (files)
          ChatSheetAction(
            icon: icons.file,
            label: strings.attachFile,
            tint: chat.senderNameColor(_fileTint),
            onTap: () => _choose(context, AttachmentSource.file),
          ),
      ],
    );
  }

  void _choose(BuildContext context, AttachmentSource source) =>
      Navigator.of(context).pop(source);
}
