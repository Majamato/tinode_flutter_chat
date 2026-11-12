import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Sweeps a band of light over the [SkeletonBone]s in [child], start to
/// end, every [period]: one ticker for the whole skeleton. Each bone keeps
/// its own colour; only the band is painted over it. With Reduce motion
/// the bones hold still.
///
/// Screen readers hear "Loading…" once instead of the bones, and the
/// skeleton takes no touches. Watches nothing.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({required this.child, this.highlightColor, super.key});

  /// One sweep of the band.
  static const period = Duration(milliseconds: 1400);

  final Widget child;

  /// The band's colour at its middle; the theme's `skeletonHighlightColor`
  /// when null.
  final Color? highlightColor;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SkeletonShimmer.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bones = IgnorePointer(child: ExcludeSemantics(child: widget.child));
    return Semantics(
      label: TinodeChatStrings.of(context).loading,
      liveRegion: true,
      child: MediaQuery.disableAnimationsOf(context)
          ? bones
          : _Sweep(
              progress: _controller,
              color:
                  widget.highlightColor ??
                  TinodeChatTheme.of(context).skeletonHighlightColor,
              rtl: Directionality.of(context) == TextDirection.rtl,
              child: bones,
            ),
    );
  }
}

/// Paints the band over [child] where the animation has it.
class _Sweep extends AnimatedWidget {
  const _Sweep({
    required Animation<double> progress,
    required this.color,
    required this.rtl,
    required this.child,
  }) : super(listenable: progress);

  final Color color;
  final bool rtl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    final clear = color.withValues(alpha: 0);
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        begin: const Alignment(-1, -0.3),
        end: const Alignment(1, 0.3),
        colors: [clear, color, clear],
        stops: const [0.35, 0.5, 0.65],
        transform: _Slide(rtl ? 1 - t : t),
      ).createShader(bounds),
      child: child,
    );
  }
}

/// Moves the gradient from a width before its bounds to a width past them.
class _Slide extends GradientTransform {
  const _Slide(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}
