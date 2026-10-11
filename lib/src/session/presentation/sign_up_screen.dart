import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/sign_up_form.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Signing up: a new user's login, password and name. Signing up logs in,
/// which replaces the login screens with the chat.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  /// Pushes the screen over the login screen.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TinodeChatStrings.of(context).signUpTitle)),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: SizedBox(width: 400, child: SignUpForm()),
          ),
        ),
      ),
    );
  }
}
