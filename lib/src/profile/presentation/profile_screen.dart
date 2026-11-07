import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_body.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// The user's own profile: photo and name, under the glass app bar, whose
/// back button names [backLabel]. The password, logging out and deleting
/// the account are on the account screen. Watches nothing itself.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.backLabel, super.key});

  /// Pushes the screen onto the chat's navigator.
  static Future<void> open(BuildContext context, {required String backLabel}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileScreen(backLabel: backLabel),
        ),
      );

  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      screen: const TinodeProfileScreen(),
      appBar: TinodeAppBar(
        title: Text(TinodeChatStrings.of(context).profile),
        leading: TinodeBackButton(label: Text(backLabel)),
      ),
      body: const SafeArea(child: ProfileBody()),
    );
  }
}
