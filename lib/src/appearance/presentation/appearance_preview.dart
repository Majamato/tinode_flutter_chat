import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/bubble_frame.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/dot_grid_painter.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A mini chat in the theme in use: a question and the user's answer,
/// naming the palette, which pops in again from its tail whenever the
/// palette changes. Decoration for screen readers. Watches the appearance.
class AppearancePreview extends StatelessWidget {
  const AppearancePreview({super.key});

  static const _padding = EdgeInsets.symmetric(horizontal: 13, vertical: 8);

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final theme = TinodeChatTheme.of(context);
    final palette = AppearanceScope.maybeOf(context)?.palette;
    final text = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 21 / 15);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: DotGridPainter(
            background: theme.wallpaperColor,
            dot: theme.wallpaperDotColor,
            grid: 22,
            shifts: const [Offset(11, 11)],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
            child: Column(
              spacing: 14,
              children: [
                BubbleFrame(
                  own: false,
                  tail: true,
                  padding: _padding,
                  body: Text(
                    strings.appearancePreviewQuestion,
                    style: text?.copyWith(color: theme.onPeerBubbleColor),
                  ),
                ),
                _PopIn(
                  key: ValueKey(palette?.id),
                  child: BubbleFrame(
                    own: true,
                    tail: true,
                    padding: _padding,
                    body: Text(
                      strings.appearancePreviewAnswer(palette?.label ?? ''),
                      style: text?.copyWith(color: theme.onOwnBubbleColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grows [child] from its bottom end corner as it first shows: .6 to
/// 1.06 to 1 on the spring; with Reduce motion it only fades in.
class _PopIn extends StatefulWidget {
  const _PopIn({required this.child, super.key});

  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 380);

  late final _controller = AnimationController(vsync: this);
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.06), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 30),
  ]).animate(_controller);
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7),
  );
  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_controller.isDismissed) {
      _controller.duration = _still
          ? TinodeChatTheme.of(context).fadeDuration
          : _duration;
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faded = FadeTransition(opacity: _opacity, child: widget.child);
    if (_still) {
      return faded;
    }
    return ScaleTransition(
      scale: _scale,
      alignment: Directionality.of(context) == TextDirection.rtl
          ? Alignment.bottomLeft
          : Alignment.bottomRight,
      child: faded,
    );
  }
}
