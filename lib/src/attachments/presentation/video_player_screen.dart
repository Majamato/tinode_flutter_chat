import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_player_view.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// A video full screen, playing, always on black. Watches nothing itself:
/// the bubble hands it the downloaded file.
class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({required this.title, required this.path, super.key});

  /// Pushes the player for the video at [path], named [title].
  static Future<void> open(BuildContext context, String title, String path) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoPlayerScreen(title: title, path: path),
        ),
      );

  final String title;
  final String path;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      screen: const TinodeVideoPlayerScreen(),
      backgroundColor: Colors.black,
      appBar: TinodeAppBar(
        fadeColor: Colors.black,
        opaque: true,
        overlayBrightness: Brightness.dark,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: const TinodeBackButton(),
      ),
      body: SafeArea(child: VideoPlayerView(path: path, autoplay: true)),
    );
  }
}
