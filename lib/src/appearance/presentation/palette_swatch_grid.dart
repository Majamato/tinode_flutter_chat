import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/palette_swatch.dart';

/// The host's palettes, five to a row, the one in use ringed; a tap picks
/// another, with a haptic tick. Watches the appearance.
class PaletteSwatchGrid extends StatelessWidget {
  const PaletteSwatchGrid({super.key});

  static const _columns = 5;

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) {
      return const SizedBox.shrink();
    }
    final palettes = appearance.palettes;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      child: Column(
        spacing: 14,
        children: [
          for (var start = 0; start < palettes.length; start += _columns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = start; i < start + _columns; i++)
                  Expanded(
                    child: i < palettes.length
                        ? PaletteSwatch(
                            palette: palettes[i],
                            selected: palettes[i].id == appearance.palette.id,
                            onTap: () {
                              if (palettes[i].id != appearance.palette.id) {
                                unawaited(HapticFeedback.selectionClick());
                                appearance.selectPalette(palettes[i].id);
                              }
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
