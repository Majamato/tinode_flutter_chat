import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:video_player/video_player.dart';

/// Plays the video at [path], in white on a dark background: the picture
/// in its own shape (fading in once loaded), then play or pause, a bar to
/// scrub and the time, in place from the start. A tap
/// on the picture plays or pauses it too. With a [clip], it plays only that
/// part, over and over, and [clipBar] takes the place of the bar. Watches
/// nothing but its player and [clip].
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({
    required this.path,
    this.autoplay = false,
    this.clip,
    this.clipBar,
    this.onReady,
    super.key,
  });

  final String path;

  /// Whether it starts playing once loaded.
  final bool autoplay;

  /// The part to play; changing it pauses and goes to its start.
  final ValueNotifier<VideoTrim?>? clip;

  /// Shown in place of the bar to scrub.
  final Widget? clipBar;

  /// Told how long the video plays once loaded, or null when it can't be.
  final ValueChanged<Duration?>? onReady;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _player = VideoPlayerController.file(
    File(widget.path),
  );
  var _failed = false;
  var _seeking = false;
  var _seekAgain = false;
  VideoTrim? _lastClip;

  late final Listenable _changes = Listenable.merge([_player, ?widget.clip]);

  static const _fadeIn = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _player.addListener(_loop);
    widget.clip?.addListener(_onClip);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await _player.initialize();
      widget.onReady?.call(_player.value.duration);
      if (widget.autoplay) {
        await _player.play();
      }
    } on Object {
      if (mounted) {
        setState(() => _failed = true);
        widget.onReady?.call(null);
      }
    }
  }

  @override
  void dispose() {
    _player.removeListener(_loop);
    widget.clip?.removeListener(_onClip);
    unawaited(_player.dispose());
    super.dispose();
  }

  /// Starts the [VideoPlayerView.clip] again once it has played through.
  void _loop() {
    final clip = widget.clip?.value;
    final value = _player.value;
    if (clip == null || _seeking || value.position < clip.end) {
      return;
    }
    if (value.isPlaying) {
      unawaited(_seekToClip());
    } else if (value.isCompleted) {
      unawaited(_playFromClipStart());
    }
  }

  void _onClip() {
    final clip = widget.clip?.value;
    if (clip == null || clip == _lastClip) {
      return;
    }
    // The first selection, set once loaded, changes nothing on screen.
    final first = _lastClip == null;
    _lastClip = clip;
    if (!first) {
      unawaited(_player.pause());
      unawaited(_seekToClip());
    }
  }

  /// Goes to the clip's start, the latest one: a drag asks far more often
  /// than a player can seek.
  Future<void> _seekToClip() async {
    if (_seeking) {
      _seekAgain = true;
      return;
    }
    _seeking = true;
    try {
      do {
        _seekAgain = false;
        if (widget.clip?.value case final clip?) {
          await _player.seekTo(clip.start);
        }
      } while (_seekAgain && mounted);
    } finally {
      _seeking = false;
    }
  }

  Future<void> _playFromClipStart() async {
    await _seekToClip();
    if (mounted) {
      await _player.play();
    }
  }

  void _toggle() {
    final value = _player.value;
    if (value.isPlaying) {
      unawaited(_player.pause());
      return;
    }
    final clip = widget.clip?.value;
    if (clip != null &&
        (value.position < clip.start || value.position >= clip.end)) {
      unawaited(_playFromClipStart());
    } else {
      unawaited(_player.play());
    }
  }

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
    return ListenableBuilder(
      listenable: _changes,
      builder: (context, _) {
        final value = _player.value;
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
              clip: widget.clip?.value,
              clipBar: widget.clipBar,
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
    required this.clip,
    required this.clipBar,
  });

  final VideoPlayerController player;
  final VideoPlayerValue value;

  /// Null until the video is ready.
  final VoidCallback? onToggle;

  /// The part being played, if only a part is.
  final VideoTrim? clip;

  /// Shown in place of the bar to scrub, when there is a [clip].
  final Widget? clipBar;

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final time = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final clip = this.clip;
    final bar = clip == null ? null : clipBar;
    final position = value.position - (clip?.start ?? Duration.zero);
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
          Text(
            formatCallDuration(position.isNegative ? Duration.zero : position),
            style: time,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                bar ??
                (value.isInitialized
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
                      )),
          ),
          const SizedBox(width: 12),
          Text(formatCallDuration(clip?.length ?? value.duration), style: time),
        ],
      ),
    );
  }
}
