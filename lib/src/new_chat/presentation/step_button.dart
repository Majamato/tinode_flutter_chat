import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';

/// The main action of a new group screen, at the end of its app bar: a
/// small tonal pill with [label], shorter than the bar's 44 px buttons and
/// in 14 px text, so it leaves the title room. Disabled while [onPressed]
/// is null, a spinner while [busy]. Watches nothing.
class StepButton extends StatelessWidget {
  const StepButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  /// Its height.
  static const _height = 34.0;

  /// How far its text may grow, less than the bar's 1.3 so a large font
  /// setting doesn't make it crowd the title.
  static const _maxTextScale = 1.15;

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxTextScale,
      child: GlassSurface(
        tonal: true,
        child: TextButton(
          onPressed: busy ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: color.withValues(alpha: 0.45),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: const Size.square(_height),
            fixedSize: const Size.fromHeight(_height),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
          ),
          child: busy
              ? SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
