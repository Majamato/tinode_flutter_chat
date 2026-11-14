import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// What looks like a search field under an app bar: a 40 px pill showing
/// [label] that calls [onTap], filled like an input in light mode and
/// glass in dark mode. Screen readers read it as a button named
/// [semanticsLabel]. Watches nothing.
class SearchPill extends StatelessWidget {
  const SearchPill({
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  /// Its height.
  static const height = 40.0;

  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.outline;
    final content = InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              TinodeChatIcons.of(context).search,
              size: ChatIconSize.label,
              color: TinodeChatTheme.of(context).iconPassiveColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: theme.brightness == Brightness.light
          // On a white list white glass vanishes: a filled field, as in
          // iOS, shows where the search starts.
          ? Material(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: content,
            )
          : GlassSurface(
              child: Material(type: MaterialType.transparency, child: content),
            ),
    );
  }
}
