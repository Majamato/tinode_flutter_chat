import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/photo_time_chip.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';

/// How long a video plays, over its poster: a camera glyph and the time,
/// white on the photo chip's pill.
class VideoDurationChip extends StatelessWidget {
  const VideoDurationChip({required this.duration, super.key});

  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final duration = this.duration;
    return PhotoTimeChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TinodeChatIcons.of(context).video,
            size: ChatIconSize.tiny,
            color: PhotoTimeChip.footerColor,
          ),
          if (duration != null) ...[
            const SizedBox(width: 4),
            Text(
              formatCallDuration(duration),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: PhotoTimeChip.footerColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
