import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/app/presentation/tinode_appearance.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One palette to pick: a 48 px circle split diagonally into its accent
/// and its light primary, the name below, and a ring in the theme's
/// primary while [selected]. Watches
/// nothing.
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
    super.key,
  });

  static const _size = 48.0;

  final TinodeAppearancePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final colors = palette.colors;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                curve: chat.springCurve,
                width: _size,
                height: _size,
                margin: const EdgeInsets.all(5.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.accent,
                      colors.accent,
                      colors.primary,
                      colors.primary,
                    ],
                    stops: const [0, 0.38, 0.38, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      // The palette in use, so the theme's own primary.
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      spreadRadius: selected ? 5.5 : 0,
                    ),
                    BoxShadow(
                      color: selected ? chat.cardColor : Colors.transparent,
                      spreadRadius: selected ? 3 : 0,
                    ),
                  ],
                ),
              ),
              Text(
                palette.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
