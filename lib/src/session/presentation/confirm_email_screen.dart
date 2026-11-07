import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/confirm_email_form.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

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
    return GlassScaffold(
      screen: const TinodeConfirmEmailScreen(),
      appBar: TinodeAppBar(
        title: Text(TinodeChatStrings.of(context).confirmEmailTitle),
        leading: const TinodeBackButton(),
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
