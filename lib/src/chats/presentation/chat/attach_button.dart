import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attach_sheet.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_preview_screen.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/media_camera_screen.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_icon_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The composer's round glass button that sends a photo, a video or a
/// file: the attach menu, the picker or the in-app camera, then a preview
/// with a caption. Watches nothing; failures show through the composer.
class AttachButton extends ConsumerWidget {
  const AttachButton({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassIconButton(
      tooltip: TinodeChatStrings.of(context).attach,
      icon: TinodeChatIcons.of(context).attach,
      onPressed: () => unawaited(_attach(context, ref)),
    );
  }

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final source = await showChatSheet<AttachmentSource>(
      context,
      builder: (_) => const AttachSheet(),
    );
    if (source == null || !context.mounted) {
      return;
    }
    final send = ref.read(sendControllerProvider(topic).notifier);
    final PickedFile? file;
    if (source == AttachmentSource.camera) {
      final capture = await MediaCameraScreen.open(
        context,
        maxVideoDuration: ref
            .read(tinodeAttachmentLimitsProvider)
            .maxVideoDuration,
      );
      file = capture == null ? null : await send.captured(capture);
    } else {
      file = await send.pick(source);
    }
    if (file == null || !context.mounted) {
      return;
    }
    final caption = await AttachmentPreviewScreen.open(context, file);
    if (caption == null) {
      return;
    }
    await send.sendAttachment(file, caption: caption);
  }
}
