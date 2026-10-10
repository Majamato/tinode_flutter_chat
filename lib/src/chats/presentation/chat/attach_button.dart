import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attach_sheet.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_preview_screen.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Sends an image or a file: the attach menu, the picker, then a preview
/// with a caption. Watches nothing; failures show through the composer.
class AttachButton extends ConsumerWidget {
  const AttachButton({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: TinodeChatStrings.of(context).attach,
      icon: const Icon(Icons.attach_file),
      onPressed: () => unawaited(_attach(context, ref)),
    );
  }

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<AttachmentSource>(
      context: context,
      builder: (_) => const AttachSheet(),
    );
    if (source == null || !context.mounted) {
      return;
    }
    final send = ref.read(sendControllerProvider(topic).notifier);
    final file = await send.pick(source);
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
