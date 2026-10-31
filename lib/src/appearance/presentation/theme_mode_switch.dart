import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/sliding_segments.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Light | Dark | System, with the primary pill sliding under the choice.
/// Watches the appearance.
class ThemeModeSwitch extends StatelessWidget {
  const ThemeModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) {
      return const SizedBox.shrink();
    }
    final strings = TinodeChatStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return SlidingSegments(
      segments: [
        (ThemeMode.light, strings.themeLight),
        (ThemeMode.dark, strings.themeDark),
        (ThemeMode.system, strings.themeSystem),
      ],
      selected: appearance.themeMode,
      onChanged: appearance.selectThemeMode,
      height: 46,
      radius: 16,
      trackColor: TinodeChatTheme.of(context).cardColor,
      pillColor: colors.primary,
      labelColor: colors.onSurface,
      selectedLabelColor: colors.onPrimary,
    );
  }
}
