import 'package:flutter/material.dart';

/// A round button of the call screen. [active] marks a control that is
/// switched off, such as a muted microphone.
class CallControlButton extends StatelessWidget {
  const CallControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.color,
    this.foregroundColor,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  /// Overrides the background, e.g. red for hanging up.
  final Color? color;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 28,
      padding: const EdgeInsets.all(14),
      style: IconButton.styleFrom(
        backgroundColor:
            color ?? (active ? colors.onInverseSurface : colors.surfaceDim),
        foregroundColor:
            foregroundColor ??
            (active ? colors.inverseSurface : colors.onSurface),
      ),
      icon: Icon(icon),
    );
  }
}
