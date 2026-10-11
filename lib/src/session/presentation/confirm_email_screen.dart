import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/confirm_email_form.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Confirming the user's email with the code the server mailed, after
/// signing up or logging in with an email not yet confirmed. Confirming
/// logs in, which replaces the login screens with the chat.
class ConfirmEmailScreen extends StatelessWidget {
  const ConfirmEmailScreen({
    required this.login,
    required this.password,
    super.key,
  });

  /// The screen as a route, for the login screens' navigator; [login] and
  /// [password] log in once the code is in.
  static Route<void> route({required String login, required String password}) =>
      MaterialPageRoute<void>(
        builder: (_) => ConfirmEmailScreen(login: login, password: password),
      );

  final String login;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TinodeChatStrings.of(context).confirmEmailTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 400,
              child: ConfirmEmailForm(login: login, password: password),
            ),
          ),
        ),
      ),
    );
  }
}
