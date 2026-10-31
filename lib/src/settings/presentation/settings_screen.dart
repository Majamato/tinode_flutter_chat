import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_tile.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/log_out_tile.dart';
import 'package:tinode_flutter_chat/src/settings/presentation/settings_profile_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_header.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_section.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/size_reporter.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The settings tab: the user's profile, the appearance when the host
/// offers one, and logging out, in cards scrolling under a frosted
/// header. Watches nothing.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _headerHeight = ValueNotifier<double>(0);

  @override
  void dispose() {
    _headerHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    return Scaffold(
      backgroundColor: TinodeChatTheme.of(context).pageColor,
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
                  padding: EdgeInsets.fromLTRB(16, top + 16, 16, bottom),
                  children: [child!],
                ),
              ),
              child: Column(
                spacing: 22,
                children: [
                  const SettingsSection(children: [SettingsProfileTile()]),
                  if (AppearanceScope.peek(context) != null)
                    const SettingsSection(children: [AppearanceTile()]),
                  const SettingsSection(children: [LogOutTile()]),
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
                title: TinodeChatStrings.of(context).settingsTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
