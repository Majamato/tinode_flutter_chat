import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/local_image.dart';

/// What a sent photo's or video's bubble shows under its own picture until
/// that has its first frame: the [standIn] its outgoing bubble left, else
/// the placeholder's grey. The stand-in was decoded at the same
/// [cacheWidth], so it paints at once. Watches nothing.
class StandInPicture extends StatelessWidget {
  const StandInPicture({
    required this.standIn,
    required this.cacheWidth,
    super.key,
  });

  final LocalFile? standIn;

  /// The width, in physical pixels, the picture is decoded at.
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final grey = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
    return switch (standIn) {
      final standIn? => Stack(
        fit: StackFit.expand,
        children: [
          grey,
          Image(
            image: ResizeImage.resizeIfNeeded(
              cacheWidth,
              null,
              localImage(standIn),
            ),
            fit: BoxFit.cover,
          ),
        ],
      ),
      null => grey,
    };
  }
}
