import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_bubble_content.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_text_layout.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/photo_time_chip.dart';

/// The inside of a message with images, videos or files: each of them, then the
/// caption with the [footer] after its last line. Without a caption the
/// footer sits on the last photo ([overPhoto]) or below the files. Watches
/// nothing; its bubble passes them in.
class AttachmentMessageBody extends StatelessWidget {
  const AttachmentMessageBody({
    required this.attachments,
    required this.caption,
    required this.color,
    required this.footer,
    this.clientId,
    super.key,
  });

  /// Around a caption under a photo.
  static const _photoCaptionPadding = EdgeInsets.fromLTRB(8, 2, 8, 6);

  final List<MessageAttachment> attachments;
  final String caption;

  /// The client ID of the user's own message, for its photos' and videos'
  /// stand-ins.
  final String? clientId;

  /// Text color of the bubble.
  final Color color;

  /// The time and status; white when [overPhoto].
  final Widget footer;

  /// Whether the footer sits on the last photo or video: there is no
  /// caption and the message ends with one.
  static bool overPhoto(List<MessageAttachment> attachments, String caption) =>
      caption.isEmpty && _isPicture(attachments.lastOrNull);

  /// Whether the message shows a photo or a video, which take the photo
  /// padding.
  static bool hasPhoto(List<MessageAttachment> attachments) =>
      attachments.any(_isPicture);

  static bool _isPicture(MessageAttachment? attachment) =>
      attachment is ImageAttachment || attachment is VideoAttachment;

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
                    ImageBubbleContent(image: image, clientId: clientId),
                    PositionedDirectional(
                      end: 6,
                      bottom: 6,
                      child: PhotoTimeChip(child: footer),
                    ),
                  ],
                ),
              final ImageAttachment image => ImageBubbleContent(
                image: image,
                clientId: clientId,
              ),
              final VideoAttachment video
                  when onPhoto && index == attachments.length - 1 =>
                Stack(
                  children: [
                    VideoBubbleContent(video: video, clientId: clientId),
                    PositionedDirectional(
                      end: 6,
                      bottom: 6,
                      child: PhotoTimeChip(child: footer),
                    ),
                  ],
                ),
              final VideoAttachment video => VideoBubbleContent(
                video: video,
                clientId: clientId,
              ),
              final FileAttachment file => FileBubbleContent(
                file: file,
                color: color,
              ),
              // A recording among other attachments, which Tinode's apps
              // don't send, downloads and opens as a file.
              final VoiceAttachment voice => FileBubbleContent(
                file: FileAttachment(
                  ref: voice.ref,
                  bytes: voice.bytes,
                  name: voice.name,
                  size: voice.size,
                  mimeType: voice.mimeType,
                ),
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
