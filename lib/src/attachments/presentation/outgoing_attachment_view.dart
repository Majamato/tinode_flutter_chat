import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/outgoing_attachment_providers.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_size_label.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/local_image.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/upload_progress_ring.dart';

/// The image or file of a message still in the outbox, shown from its
/// staged copy, with a progress ring while [uploading]. Watches the staged
/// file.
class OutgoingAttachmentView extends ConsumerWidget {
  const OutgoingAttachmentView({
    required this.topic,
    required this.clientId,
    required this.attachment,
    required this.uploading,
    required this.color,
    super.key,
  });

  final String topic;
  final String clientId;
  final OutgoingAttachment attachment;

  /// Whether to show the upload's progress.
  final bool uploading;

  /// Text color of the bubble.
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = uploading
        ? UploadProgressRing(topic: topic, clientId: clientId, color: color)
        : null;

    if (!attachment.isImage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 40,
            child: Center(
              child:
                  ring ??
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: color,
                    size: 32,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: color),
                ),
                Text(
                  fileSizeLabel(attachment.size),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final staged = ref.watch(stagedFileProvider(attachment.stagedId)).value;
    const width = ImageBubbleContent.width;
    return SizedBox(
      width: width,
      height: width / attachment.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (staged != null)
              Image(
                image: ResizeImage.resizeIfNeeded(
                  (width * MediaQuery.devicePixelRatioOf(context)).round(),
                  null,
                  localImage(staged),
                ),
                fit: BoxFit.cover,
              )
            else
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            if (ring != null) Center(child: ring),
          ],
        ),
      ),
    );
  }
}
