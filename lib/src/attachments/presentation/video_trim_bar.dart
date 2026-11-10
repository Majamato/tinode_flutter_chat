import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Chooses the part of a video to send, in white on a dark background:
/// the video's frames, filling in as they arrive, with the chosen part
/// framed and the rest dimmed. Its two handles change it, within
/// [maxLength]; dragging its middle moves it. Left to right in every
/// language, as a timeline is. Watches [clip].
class VideoTrimBar extends StatefulWidget {
  const VideoTrimBar({
    required this.clip,
    required this.total,
    required this.maxLength,
    required this.frames,
    super.key,
  });

  /// How many frames [frames] should bring.
  static const frameCount = 10;

  final ValueNotifier<VideoTrim?> clip;

  /// How long the video plays.
  final Duration total;

  /// The longest part that can be chosen.
  final Duration maxLength;

  /// The frames, in order, up to [frameCount]; null for one that can't be
  /// taken.
  final Stream<Uint8List?> frames;

  @override
  State<VideoTrimBar> createState() => _VideoTrimBarState();
}

class _VideoTrimBarState extends State<VideoTrimBar> {
  static const _height = 44.0;
  static const _handleWidth = 12.0;
  static const _touchWidth = 44.0;
  static const _border = 2.0;
  static const _step = Duration(seconds: 1);
  static const _dim = Color(0x99000000);

  final List<Uint8List?> _shown = List.filled(VideoTrimBar.frameCount, null);
  int _nextFrame = 0;
  StreamSubscription<Uint8List?>? _frames;

  /// Where the edge being dragged, or the middle, was when the drag began,
  /// and how far it has gone since, in pixels.
  Duration _dragOrigin = Duration.zero;
  double _dragged = 0;

  @override
  void initState() {
    super.initState();
    _frames = widget.frames.listen(_onFrame, onError: (Object _) {});
  }

  void _onFrame(Uint8List? frame) {
    if (_nextFrame < _shown.length) {
      setState(() => _shown[_nextFrame++] = frame);
    }
  }

  @override
  void dispose() {
    unawaited(_frames?.cancel());
    super.dispose();
  }

  VideoTrim _withStart(VideoTrim clip, Duration value) =>
      clip.withStart(value, total: widget.total, maxLength: widget.maxLength);

  VideoTrim _withEnd(VideoTrim clip, Duration value) =>
      clip.withEnd(value, total: widget.total, maxLength: widget.maxLength);

  void _setStart(Duration value) {
    final clip = widget.clip;
    clip.value = _withStart(clip.value!, value);
  }

  void _setEnd(Duration value) {
    final clip = widget.clip;
    clip.value = _withEnd(clip.value!, value);
  }

  void _moveTo(Duration value) {
    final clip = widget.clip;
    clip.value = clip.value?.movedTo(value, total: widget.total);
  }

  /// A drag on an area that starts from [origin], applying each new
  /// position to [apply].
  Widget _dragArea({
    required double perMs,
    required Duration Function() origin,
    required void Function(Duration value) apply,
    Widget? child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        _dragOrigin = origin();
        _dragged = 0;
      },
      onHorizontalDragUpdate: (details) {
        _dragged += details.delta.dx;
        apply(_dragOrigin + Duration(milliseconds: (_dragged / perMs).round()));
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final track = constraints.maxWidth - 2 * _handleWidth;
            final perMs = track / widget.total.inMilliseconds.clamp(1, 1 << 62);
            return ValueListenableBuilder<VideoTrim?>(
              valueListenable: widget.clip,
              builder: (context, clip, _) {
                if (clip == null) {
                  return const SizedBox.shrink();
                }
                final left = clip.start.inMilliseconds * perMs + _handleWidth;
                final right = clip.end.inMilliseconds * perMs + _handleWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      left: _handleWidth,
                      right: _handleWidth,
                      child: _Frames(frames: _shown),
                    ),
                    Positioned(
                      left: _handleWidth,
                      width: left - _handleWidth,
                      top: 0,
                      bottom: 0,
                      child: const ColoredBox(color: _dim),
                    ),
                    Positioned(
                      left: right,
                      right: _handleWidth,
                      top: 0,
                      bottom: 0,
                      child: const ColoredBox(color: _dim),
                    ),
                    Positioned(
                      left: left,
                      width: right - left,
                      top: 0,
                      bottom: 0,
                      child: _dragArea(
                        perMs: perMs,
                        origin: () => widget.clip.value!.start,
                        apply: _moveTo,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: Colors.white,
                                width: _border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: left - (_handleWidth + _touchWidth) / 2,
                      width: _touchWidth,
                      top: 0,
                      bottom: 0,
                      child: Semantics(
                        slider: true,
                        label: strings.trimStart,
                        value: formatCallDuration(clip.start),
                        increasedValue: formatCallDuration(
                          _withStart(clip, clip.start + _step).start,
                        ),
                        decreasedValue: formatCallDuration(
                          _withStart(clip, clip.start - _step).start,
                        ),
                        onIncrease: () => _setStart(clip.start + _step),
                        onDecrease: () => _setStart(clip.start - _step),
                        child: _dragArea(
                          perMs: perMs,
                          origin: () => widget.clip.value!.start,
                          apply: _setStart,
                          child: const _Handle(key: ValueKey('trimStart')),
                        ),
                      ),
                    ),
                    Positioned(
                      left: right + (_handleWidth - _touchWidth) / 2,
                      width: _touchWidth,
                      top: 0,
                      bottom: 0,
                      child: Semantics(
                        slider: true,
                        label: strings.trimEnd,
                        value: formatCallDuration(clip.end),
                        increasedValue: formatCallDuration(
                          _withEnd(clip, clip.end + _step).end,
                        ),
                        decreasedValue: formatCallDuration(
                          _withEnd(clip, clip.end - _step).end,
                        ),
                        onIncrease: () => _setEnd(clip.end + _step),
                        onDecrease: () => _setEnd(clip.end - _step),
                        child: _dragArea(
                          perMs: perMs,
                          origin: () => widget.clip.value!.end,
                          apply: _setEnd,
                          child: const _Handle(key: ValueKey('trimEnd')),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The strip of frames, grey where one hasn't arrived.
class _Frames extends StatelessWidget {
  const _Frames({required this.frames});

  static const _placeholder = Color(0x1FFFFFFF);

  final List<Uint8List?> frames;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final frame in frames)
          Expanded(
            child: frame == null
                ? const ColoredBox(color: _placeholder)
                : Image.memory(frame, fit: BoxFit.cover, gaplessPlayback: true),
          ),
      ],
    );
  }
}

/// A white handle, in the middle of its touch target.
class _Handle extends StatelessWidget {
  const _Handle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _VideoTrimBarState._handleWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Container(width: 2, height: 14, color: Colors.black45),
      ),
    );
  }
}
