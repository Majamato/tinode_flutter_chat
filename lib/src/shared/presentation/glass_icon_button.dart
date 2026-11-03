import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';

/// A round [GlassSurface] button with an icon in [color] (`onSurface` by
/// default), as in the app bar and the composer. [onPressed] null disables
/// it. [onGlass] leaves out its own glass, for buttons sharing one island
/// of glass (the chat's app bar actions). Watches nothing.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.onGlass = false,
    super.key,
  });

  /// Its diameter.
  static const size = 44.0;

  /// Its width [onGlass]: narrower than [size], so buttons sharing an
  /// island sit closer, and as tall.
  static const islandWidth = 40.0;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  /// Whether it already sits on glass, an island it shares with other
  /// buttons, and so draws none of its own.
  final bool onGlass;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: onGlass ? islandWidth : size,
        height: size,
      ),
      icon: Icon(icon, size: 22),
    );
    return onGlass ? button : GlassSurface(child: button);
  }
}
