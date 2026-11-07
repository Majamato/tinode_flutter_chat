import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// An image full screen, to zoom and pan, always on black. Watches nothing
/// itself: the bubble hands it the image it already has.
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
    return GlassScaffold(
      screen: const TinodeImageViewerScreen(),
      backgroundColor: Colors.black,
      appBar: TinodeAppBar(
        fadeColor: Colors.black,
        overlayBrightness: Brightness.dark,
        title: Text(
          image.name ?? TinodeChatStrings.of(context).imageLabel,
          style: const TextStyle(color: Colors.white),
        ),
        leading: const TinodeBackButton(),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image(image: provider)),
      ),
    );
  }
}
