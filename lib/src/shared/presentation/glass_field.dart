import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// A text field in an app bar's row: [child] on a pill as tall as the row,
/// filled like an input in light mode, where white glass would vanish on a
/// white list, and glass in dark mode. The theme's own fill, borders and
/// padding don't reach [child]. Watches nothing.
class GlassField extends StatelessWidget {
  const GlassField({required this.child, super.key});

  /// Replaces the theme's field, so its fill and borders stay out of the
  /// pill, and leaves the text room to grow at 1.3 times within the row.
  static const _input = InputDecorationThemeData(
    isDense: true,
    contentPadding: EdgeInsetsDirectional.only(top: 4, end: 14, bottom: 4),
    prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 24),
  );

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = Theme(
      data: theme.copyWith(inputDecorationTheme: _input),
      child: Align(child: child),
    );
    return SizedBox(
      height: TinodeAppBar.rowHeight,
      child: theme.brightness == Brightness.light
          ? Material(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: field,
            )
          : GlassSurface(child: field),
    );
  }
}
