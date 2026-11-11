import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_text_layout.dart';

/// Attachments one above the other, then the caption with the [footer]
/// after its last line, at the bubble's end edge; without a caption, the
/// footer alone at the end. Shared by sent and outgoing bubbles so a
/// message keeps its layout when it lands. Watches nothing.
class CaptionedAttachments extends StatelessWidget {
  const CaptionedAttachments({
    required this.attachments,
    required this.caption,
    required this.media,
    required this.color,
    this.footer,
    super.key,
  });

  /// Around a caption under a photo.
  static const _photoCaptionPadding = EdgeInsets.fromLTRB(8, 2, 8, 6);

  /// Each must report its intrinsic width, as the column takes the widest
  /// of them: give one a fixed size rather than a `LayoutBuilder`, which
  /// throws.
  final List<Widget> attachments;
  final String caption;

  /// Whether a photo or video is shown, which takes the photo caption
  /// padding.
  final bool media;

  /// Text color of the bubble.
  final Color color;

  /// The time and status; null when an attachment carries them.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    // As wide as its widest child, so the caption can span the photos.
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, attachment) in attachments.indexed)
            Padding(
              padding: EdgeInsets.only(
                bottom: index < attachments.length - 1 ? 4 : 0,
              ),
              child: attachment,
            ),
          if (caption.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: media
                    ? _photoCaptionPadding
                    : const EdgeInsets.only(top: 4),
                child: BubbleTextLayout(
                  text: Text(
                    caption,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: color),
                  ),
                  footer: footer ?? const SizedBox.shrink(),
                ),
              ),
            )
          else if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: footer,
              ),
            ),
        ],
      ),
    );
  }
}
