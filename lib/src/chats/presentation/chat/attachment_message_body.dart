import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';

/// The inside of a message with images or files: each of them, then the
/// caption. Watches nothing; its bubble passes them in.
class AttachmentMessageBody extends StatelessWidget {
  const AttachmentMessageBody({
    required this.attachments,
    required this.caption,
    required this.color,
    super.key,
  });

  final List<MessageAttachment> attachments;
  final String caption;

  /// Text color of the bubble.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final attachment in attachments)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: switch (attachment) {
              final ImageAttachment image => ImageBubbleContent(image: image),
              final FileAttachment file => FileBubbleContent(
                file: file,
                color: color,
              ),
            },
          ),
        if (caption.isNotEmpty)
          Text(
            caption,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
      ],
    );
  }
}
