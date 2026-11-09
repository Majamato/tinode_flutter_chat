import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:video_player/video_player.dart';

/// Plays the video at [path], in white on a dark background: the picture
/// in its own shape (fading in once loaded), then play or pause, a bar to
/// scrub and the time, in place from the start. A tap
/// on the picture plays or pauses it too. Watches nothing but its player.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({required this.path, this.autoplay = false, super.key});

  final String path;

  /// Whether it starts playing once loaded.
  final bool autoplay;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _player = VideoPlayerController.file(
    File(widget.path),
  );
  var _failed = false;

  static const _fadeIn = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await _player.initialize();
      if (widget.autoplay) {
        await _player.play();
      }
    } on Object {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  void _toggle() =>
      unawaited(_player.value.isPlaying ? _player.pause() : _player.play());

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Text(
          TinodeChatStrings.of(context).videoFailed,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _player,
      builder: (context, value, _) {
        final ready = value.isInitialized;
        // The controls hold their place from the start, and the picture
        // fades in over the spinner: nothing moves once it loads.
        return Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: ready ? _toggle : null,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: _fadeIn,
                    child: ready
                        ? AspectRatio(
                            aspectRatio: value.aspectRatio,
                            child: VideoPlayer(_player),
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
            _Controls(
              player: _player,
              value: value,
              onToggle: ready ? _toggle : null,
            ),
          ],
        );
      },
    );
  }
}

/// Play or pause, the scrubbing bar and the time, in white.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.player,
    required this.value,
    required this.onToggle,
  });

  final VideoPlayerController player;
  final VideoPlayerValue value;

  /// Null until the video is ready.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final time = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: value.isPlaying ? strings.pauseVideo : strings.playVideo,
            icon: Icon(value.isPlaying ? icons.pause : icons.play),
            color: Colors.white,
            disabledColor: Colors.white38,
            onPressed: onToggle,
          ),
          Text(formatCallDuration(value.position), style: time),
          const SizedBox(width: 12),
          Expanded(
            child: value.isInitialized
                ? VideoProgressIndicator(
                    player,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24,
                    ),
                  )
                // The same empty bar, standing still until it can play.
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(
                      value: 0,
                      backgroundColor: Colors.white24,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Text(formatCallDuration(value.duration), style: time),
        ],
      ),
    );
  }
}
