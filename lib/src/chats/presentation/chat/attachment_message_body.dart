import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_text_layout.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/photo_time_chip.dart';

/// The inside of a message with images or files: each of them, then the
/// caption with the [footer] after its last line. Without a caption the
/// footer sits on the last photo ([overPhoto]) or below the files. Watches
/// nothing; its bubble passes them in.
class AttachmentMessageBody extends StatelessWidget {
  const AttachmentMessageBody({
    required this.attachments,
    required this.caption,
    required this.color,
    required this.footer,
    super.key,
  });

  /// Around a caption under a photo.
  static const _photoCaptionPadding = EdgeInsets.fromLTRB(8, 2, 8, 6);

  final List<MessageAttachment> attachments;
  final String caption;

  /// Text color of the bubble.
  final Color color;

  /// The time and status; white when [overPhoto].
  final Widget footer;

  /// Whether the footer sits on the last photo: there is no caption and
  /// the message ends with a photo.
  static bool overPhoto(List<MessageAttachment> attachments, String caption) =>
      caption.isEmpty && attachments.lastOrNull is ImageAttachment;

  /// Whether the message shows a photo, which takes the photo padding.
  static bool hasPhoto(List<MessageAttachment> attachments) =>
      attachments.any((a) => a is ImageAttachment);

  @override
  Widget build(BuildContext context) {
    final onPhoto = overPhoto(attachments, caption);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, attachment) in attachments.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index < attachments.length - 1 ? 4 : 0,
            ),
            child: switch (attachment) {
              final ImageAttachment image
                  when onPhoto && index == attachments.length - 1 =>
                Stack(
                  children: [
                    ImageBubbleContent(image: image),
                    PositionedDirectional(
                      end: 6,
                      bottom: 6,
                      child: PhotoTimeChip(child: footer),
                    ),
                  ],
                ),
              final ImageAttachment image => ImageBubbleContent(image: image),
              final FileAttachment file => FileBubbleContent(
                file: file,
                color: color,
              ),
            },
          ),
        if (caption.isNotEmpty)
          Padding(
            padding: hasPhoto(attachments)
                ? _photoCaptionPadding
                : const EdgeInsets.only(top: 4),
            child: BubbleTextLayout(
              text: Text(
                caption,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: color),
              ),
              footer: footer,
            ),
          )
        else if (!onPhoto)
          Align(alignment: AlignmentDirectional.centerEnd, child: footer),
      ],
    );
  }
}
