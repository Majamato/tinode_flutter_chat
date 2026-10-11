import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/password_reset_form.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Resetting a forgotten password: an emailed code, then a new password.
class PasswordResetScreen extends StatelessWidget {
  const PasswordResetScreen({super.key});

  /// Pushes the screen over the login screen; true once the password is
  /// set.
  static Future<bool> open(BuildContext context) async =>
      await Navigator.of(context).push(
        MaterialPageRoute<bool>(builder: (_) => const PasswordResetScreen()),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TinodeChatStrings.of(context).resetPasswordTitle),
      ),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: SizedBox(width: 400, child: PasswordResetForm()),
          ),
        ),
      ),
    );
  }
}
