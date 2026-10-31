import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A row of [segments] with a pill that slides under the [selected] one on
/// the theme's spring (at once with Reduce motion). The segments are
/// equally wide. Watches nothing.
class SlidingSegments<T> extends StatelessWidget {
  const SlidingSegments({
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.height,
    required this.radius,
    required this.trackColor,
    required this.pillColor,
    required this.labelColor,
    required this.selectedLabelColor,
    this.pillShadow,
    super.key,
  });

  static const _inset = 4.0;

  /// Each segment's value and label, in order.
  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  /// The track's corner radius; the pill's is [_inset] less.
  final double radius;
  final Color trackColor;
  final Color pillColor;
  final List<BoxShadow>? pillShadow;
  final Color labelColor;
  final Color selectedLabelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : chat.springDuration;
    final index = segments.indexWhere((segment) => segment.$1 == selected);
    final last = segments.length - 1;
    return Container(
      height: height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: AlignmentDirectional(
              last == 0 ? 0 : -1 + 2 * index / last,
              0,
            ),
            duration: duration,
            curve: chat.springCurve,
            child: FractionallySizedBox(
              widthFactor: 1 / segments.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(radius - _inset),
                  boxShadow: pillShadow,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (value, label) in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    inMutuallyExclusiveGroup: true,
                    selected: value == selected,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius - _inset),
                      onTap: value == selected ? null : () => onChanged(value),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: chat.fadeDuration,
                          style: theme.textTheme.labelLarge!.copyWith(
                            fontSize: 15,
                            color: value == selected
                                ? selectedLabelColor
                                : labelColor,
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
