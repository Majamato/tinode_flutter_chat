import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_form.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The built-in login screen, shown when the host gave no credentials or
/// its token was rejected.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TinodeChatStrings.of(context).loginTitle)),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: SizedBox(width: 400, child: LoginForm()),
          ),
        ),
      ),
    );
  }
}
