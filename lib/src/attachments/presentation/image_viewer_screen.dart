import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// An image full screen, to zoom and pan. Watches nothing: the bubble
/// hands it the image it already has.
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({
    required this.image,
    required this.provider,
    super.key,
  });

  /// Pushes the viewer for [image], shown from [provider].
  static Future<void> open(
    BuildContext context,
    ImageAttachment image,
    ImageProvider<Object> provider,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ImageViewerScreen(image: image, provider: provider),
    ),
  );

  final ImageAttachment image;
  final ImageProvider<Object> provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(image.name ?? TinodeChatStrings.of(context).imageLabel),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image(image: provider)),
      ),
    );
  }
}
