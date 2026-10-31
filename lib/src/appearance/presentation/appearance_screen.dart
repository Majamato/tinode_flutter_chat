import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_back_button.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_preview.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/palette_swatch_grid.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/reset_palette_button.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/theme_mode_switch.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/screen_header.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Picks the look of the app: a live preview, the host's palettes (when
/// it offers more than one), light, dark or system, the host's own extra
/// widget, and the way back to the default palette, under a header whose
/// back button names [backLabel]. Watches nothing itself.
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
    return Scaffold(
      backgroundColor: chat.pageColor,
      appBar: ScreenHeader(
        title: strings.appearance,
        leading: AppearanceBackButton(label: backLabel),
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.paddingOf(context).bottom + 40,
          ),
          children: [
            Column(
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
          ],
        ),
      ),
    );
  }
}
