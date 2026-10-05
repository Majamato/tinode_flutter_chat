import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/login_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_error_text.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_submit_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Login name and password fields. Watches nothing: the button and the
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

  void _onSubmit() => ref
      .read(loginControllerProvider.notifier)
      .submit(_login.text, _password.text);

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
            onSubmitted: (_) => _onSubmit(),
          ),
          const SizedBox(height: 8),
          const LoginErrorText(),
          const SizedBox(height: 16),
          LoginSubmitButton(onSubmit: _onSubmit),
        ],
      ),
    );
  }
}
