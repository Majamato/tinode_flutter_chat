import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/outgoing_attachment_providers.dart';
import 'package:tinode_flutter_chat/src/attachments/application/sent_stand_ins.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_cancel_button.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_progress_overlay.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_progress_ring.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_size_label.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/local_image.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_duration_chip.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_play_glyph.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The image, video or file of a message still in the outbox. A photo or
/// video shows from its poster (a photo without one from its staged copy),
/// under the compression's and then the upload's progress while
/// [uploading]; a file shows a progress ring in place of its icon. While
/// [uploading], an X stops it ([onCancel]). It leaves its picture as the
/// sent bubble's stand-in. Watches the staged file of a photo without a
/// poster.
///
/// The picture never blinks out: the last one shown stays while the next
/// loads, over the placeholder's grey.
class OutgoingAttachmentView extends ConsumerStatefulWidget {
  const OutgoingAttachmentView({
    required this.topic,
    required this.clientId,
    required this.attachment,
    required this.uploading,
    required this.color,
    required this.onCancel,
    super.key,
  });

  final String topic;
  final String clientId;
  final OutgoingAttachment attachment;

  /// Whether it is still on its way: compressing or uploading.
  final bool uploading;

  /// Text color of the bubble.
  final Color color;

  /// Stops the compression or upload and drops the message.
  final VoidCallback onCancel;

  @override
  ConsumerState<OutgoingAttachmentView> createState() =>
      _OutgoingAttachmentViewState();
}

class _OutgoingAttachmentViewState
    extends ConsumerState<OutgoingAttachmentView> {
  /// The picture last shown, kept while the next one loads.
  LocalFile? _shown;

  /// The picture to show: the poster, else the staged copy of a photo,
  /// else the last one shown.
  LocalFile? _picture() {
    final attachment = widget.attachment;
    final current = switch (attachment.poster) {
      final poster? =>
        // The same bytes, read again from the outbox, are the same
        // picture: no need to decode them again.
        listEquals(_shown?.bytes, poster) ? _shown : LocalFile.inMemory(poster),
      null when attachment.isImage =>
        ref.watch(stagedFileProvider(attachment.stagedId)).value,
      null => null,
    };
    return _shown = current ?? _shown;
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final uploading = widget.uploading;
    final color = widget.color;
    final topic = widget.topic;
    final clientId = widget.clientId;
    if (!attachment.isMedia) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 40,
            child: Center(
              child: uploading
                  ? AttachmentProgressRing(
                      topic: topic,
                      clientId: clientId,
                      compress: attachment.pendingCompression,
                      color: color,
                      dimension: 36,
                    )
                  : Icon(
                      TinodeChatIcons.of(context).file,
                      color: color,
                      size: ChatIconSize.xlarge,
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
          if (uploading)
            AttachmentCancelButton(onCancel: widget.onCancel, color: color),
        ],
      );
    }

    const width = ImageBubbleContent.width;
    final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context)).round();
    final shown = _picture();
    if (shown != null) {
      ref.read(sentStandInsProvider).leave(clientId, shown);
    }
    return SizedBox(
      width: width,
      height: width / attachment.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          TinodeChatTheme.of(context).photoRadius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            if (shown != null)
              Image(
                image: ResizeImage.resizeIfNeeded(
                  cacheWidth,
                  null,
                  localImage(shown),
                ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            if (attachment.isVideo) ...[
              if (!uploading) const Center(child: VideoPlayGlyph()),
              PositionedDirectional(
                start: 6,
                top: 6,
                child: VideoDurationChip(duration: attachment.duration),
              ),
            ],
            if (uploading)
              AttachmentProgressOverlay(
                topic: topic,
                clientId: clientId,
                compress: attachment.pendingCompression,
                onCancel: widget.onCancel,
              ),
          ],
        ),
      ),
    );
  }
}
