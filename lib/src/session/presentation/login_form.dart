import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/login_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/confirm_email_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/create_account_link.dart';
import 'package:tinode_flutter_chat/src/session/presentation/forgot_password_link.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_error_text.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_submit_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Login name and password fields, and links to sign up or reset a
/// forgotten password. Watches nothing: the button and the
/// error text below it watch the submission on their own.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Asks for the mailed code when the user's email isn't confirmed yet.
  Future<void> _onSubmit() async {
    final navigator = Navigator.of(context);
    final (login, password) = (_login.text.trim(), _password.text);
    if (await ref
        .read(loginControllerProvider.notifier)
        .submit(login, password)) {
      unawaited(
        navigator.push(
          ConfirmEmailScreen.route(login: login, password: password),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _login,
            decoration: InputDecoration(labelText: strings.loginField),
            autofillHints: const [AutofillHints.username],
            autocorrect: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            decoration: InputDecoration(labelText: strings.passwordField),
            autofillHints: const [AutofillHints.password],
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_onSubmit()),
          ),
          const SizedBox(height: 8),
          const LoginErrorText(),
          const SizedBox(height: 16),
          LoginSubmitButton(onSubmit: () => unawaited(_onSubmit())),
          const SizedBox(height: 8),
          const ForgotPasswordLink(),
          const CreateAccountLink(),
        ],
      ),
    );
  }
}
