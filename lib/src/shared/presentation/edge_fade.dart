import 'package:flutter/widgets.dart';

/// The fade behind floating bars: [color] solid from the screen's [edge]
/// across the [solid] fraction of its height, then easing to clear where
/// the content shows. It only paints, and never takes a touch: the bar it
/// sits behind blocks the touches on its own area, while the fade may ease
/// out past it over content that stays tappable. Watches nothing.
class EdgeFade extends StatelessWidget {
  const EdgeFade({
    required this.color,
    required this.edge,
    this.solid = 0,
    super.key,
  }) : assert(solid >= 0 && solid < 1, 'solid is a fraction below 1');

  final Color color;

  /// [VerticalDirection.up] for the top of the screen, down for the
  /// bottom.
  final VerticalDirection edge;

  /// How much of the fade, from the edge, is fully [color].
  final double solid;

  @override
  Widget build(BuildContext context) {
    final top = edge == VerticalDirection.up;
    final rest = 1 - solid;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            // Eased, so the fade has no visible edge where it starts.
            colors: [
              color,
              color,
              color.withValues(alpha: 0.85),
              color.withValues(alpha: 0.45),
              color.withValues(alpha: 0),
            ],
            stops: [0, solid, solid + rest * 0.35, solid + rest * 0.7, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
