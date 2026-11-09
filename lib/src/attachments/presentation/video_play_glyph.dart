import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';

/// The round play mark over a video's poster, or [busy] in its place (a
/// download's progress).
class VideoPlayGlyph extends StatelessWidget {
  const VideoPlayGlyph({this.busy, super.key});

  static const _size = 52.0;
  static const _background = Color(0x73000000);

  final Widget? busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: _background,
        shape: CircleBorder(),
      ),
      child: SizedBox.square(
        dimension: _size,
        child: Center(
          child:
              busy ??
              Icon(
                TinodeChatIcons.of(context).play,
                color: Colors.white,
                size: 28,
              ),
        ),
      ),
    );
  }
}
