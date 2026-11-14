import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// An image full screen, titled [title], to zoom and pan, always on black.
/// Watches nothing itself: whoever opens it hands it the image it already
/// has.
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({
    required this.provider,
    required this.title,
    super.key,
  });

  /// Pushes the viewer for the image of [provider], titled [title].
  static Future<void> open(
    BuildContext context,
    ImageProvider<Object> provider,
    String title,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ImageViewerScreen(provider: provider, title: title),
    ),
  );

  final ImageProvider<Object> provider;

  /// The app bar's title: the image's name, or whose photo it is.
  final String title;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      screen: const TinodeImageViewerScreen(),
      backgroundColor: Colors.black,
      appBar: TinodeAppBar(
        fadeColor: Colors.black,
        opaque: true,
        overlayBrightness: Brightness.dark,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: const TinodeBackButton(),
      ),
      body: SafeArea(
        child: InteractiveViewer(
          maxScale: 5,
          child: Center(child: Image(image: provider)),
        ),
      ),
    );
  }
}
