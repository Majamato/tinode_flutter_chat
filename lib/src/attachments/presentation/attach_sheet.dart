import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Where to pick an attachment from: Photo, Camera (where the device has
/// one) and File. Pops with the chosen [AttachmentSource]. Watches whether
/// there is a camera.
class AttachSheet extends ConsumerWidget {
  const AttachSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    final hasCamera = ref.watch(cameraAvailableProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: Text(strings.attachPhoto),
            onTap: () => _choose(context, AttachmentSource.gallery),
          ),
          if (hasCamera)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(strings.attachCamera),
              onTap: () => _choose(context, AttachmentSource.camera),
            ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(strings.attachFile),
            onTap: () => _choose(context, AttachmentSource.file),
          ),
        ],
      ),
    );
  }

  void _choose(BuildContext context, AttachmentSource source) =>
      Navigator.of(context).pop(source);
}
