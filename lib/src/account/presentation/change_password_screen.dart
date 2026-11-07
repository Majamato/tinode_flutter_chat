import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/account/presentation/change_password_form.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// A new password, typed twice. The login stays as it is.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  /// Pushes the screen; true once the password was changed.
  static Future<bool> open(BuildContext context) async =>
      await Navigator.of(context).push(
        MaterialPageRoute<bool>(builder: (_) => const ChangePasswordScreen()),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return GlassScaffold(
      screen: const TinodeChangePasswordScreen(),
      appBar: TinodeAppBar(
        title: Text(strings.changePassword),
        leading: TinodeBackButton(label: Text(strings.account)),
      ),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: SizedBox(width: 400, child: ChangePasswordForm()),
          ),
        ),
      ),
    );
  }
}
