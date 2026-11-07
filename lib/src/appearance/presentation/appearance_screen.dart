import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_preview.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/palette_swatch_grid.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/reset_palette_button.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/theme_mode_switch.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// Picks the look of the app: a live preview, the host's palettes (when
/// it offers more than one), light, dark or system, the host's own extra
/// widget, and the way back to the default palette, scrolling under the
/// glass app bar, whose back button names [backLabel]. Watches nothing itself.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({required this.backLabel, super.key});

  /// Pushes the screen onto the chat's navigator.
  static Future<void> open(BuildContext context, {required String backLabel}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AppearanceScreen(backLabel: backLabel),
        ),
      );

  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final chat = TinodeChatTheme.of(context);
    final palettes = AppearanceScope.peek(context)?.palettes.length ?? 0;
    final extra = AppearanceScope.extraOf(context);
    return GlassScaffold(
      screen: const TinodeAppearanceScreen(),
      backgroundColor: chat.pageColor,
      appBar: TinodeAppBar(
        title: Text(strings.appearance),
        leading: TinodeBackButton(label: Text(backLabel)),
        fadeColor: chat.pageColor,
      ),
      // No padding of its own: the list pads itself by the bars'.
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 22,
              children: [
                const AppearancePreview(),
                if (palettes > 1)
                  SettingsSection(
                    title: strings.appearanceColor,
                    footer: strings.appearanceColorHelp,
                    children: const [PaletteSwatchGrid()],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsLabel(strings.appearanceTheme),
                    const ThemeModeSwitch(),
                  ],
                ),
                ?extra,
                if (palettes > 1) const ResetPaletteButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
