import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_body.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The user's own profile and account: photo, name and note, the password
/// and deleting the account. Watches nothing itself.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Pushes the screen onto the chat's navigator.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TinodeChatStrings.of(context).profile)),
      body: const SafeArea(child: ProfileBody()),
    );
  }
}
