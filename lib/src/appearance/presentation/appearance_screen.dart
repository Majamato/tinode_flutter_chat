import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_back_button.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_preview.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/palette_swatch_grid.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/reset_palette_button.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/theme_mode_switch.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_header.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/size_reporter.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Picks the look of the app: a live preview, the host's palettes (when
/// it offers more than one), light, dark or system, the host's own extra
/// widget, and the way back to the default palette. Scrolls under a
/// frosted header whose back button names [backLabel]. Watches nothing
/// itself.
class AppearanceScreen extends StatefulWidget {
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
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  final _headerHeight = ValueNotifier<double>(0);

  @override
  void dispose() {
    _headerHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final chat = TinodeChatTheme.of(context);
    final palettes = AppearanceScope.peek(context)?.palettes.length ?? 0;
    final extra = AppearanceScope.extraOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom + 40;
    return Scaffold(
      backgroundColor: chat.pageColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder(
              valueListenable: _headerHeight,
              builder: (context, top, child) => MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, top + 8, 16, bottom),
                  children: [child!],
                ),
              ),
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
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizeReporter(
              height: _headerHeight,
              child: FrostedHeader(
                title: strings.appearance,
                leading: AppearanceBackButton(label: widget.backLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
