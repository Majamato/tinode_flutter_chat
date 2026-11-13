import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/confirm_email_screen.dart';
import 'package:tinode_flutter_chat/src/session/presentation/password_field.dart';
import 'package:tinode_flutter_chat/src/session/presentation/sign_up_button.dart';
import 'package:tinode_flutter_chat/src/session/presentation/sign_up_error_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Name, login and password fields, marked required, then the email where
/// the server needs one or the host lets users give one. The login sits
/// right above the password, as on sign-in, and says it must be unique.
/// The button sends them once the required ones are filled. When the
/// server mails a code to confirm the email, it opens the screen that
/// takes it, over the login screen. Under the button, the host's terms, if
/// any. Watches whether there is an email field and whether the server
/// needs it; the button and error text below watch the submission.
class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key});

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _name = TextEditingController();
  final _login = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _filled = Listenable.merge([_name, _login, _email, _password]);

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  static String _required(String label) => '$label *';

  bool _complete({required bool needsEmail}) =>
      _name.text.trim().isNotEmpty &&
      _login.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      (!needsEmail || _email.text.trim().isNotEmpty);

  void _submit([String? _]) => unawaited(_onSubmit());

  Future<void> _onSubmit() async {
    if (!_complete(needsEmail: ref.read(signUpNeedsEmailProvider))) {
      return;
    }
    final navigator = Navigator.of(context);
    final (login, password) = (_login.text.trim(), _password.text);
    final confirm = await ref
        .read(signUpControllerProvider.notifier)
        .submit(
          login: login,
          password: password,
          name: _name.text,
          email: _email.text,
        );
    if (confirm) {
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
    final needsEmail = ref.watch(signUpNeedsEmailProvider);
    final asksEmail = ref.watch(signUpAsksEmailProvider);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: _required(strings.displayNameField),
            ),
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _login,
            decoration: InputDecoration(
              labelText: _required(strings.signUpLoginField),
              helperText: strings.signUpLoginHelper,
              helperMaxLines: 2,
            ),
            autofillHints: const [AutofillHints.newUsername],
            autocorrect: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          PasswordField(
            controller: _password,
            label: _required(strings.passwordField),
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: asksEmail
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: asksEmail ? null : _submit,
          ),
          if (asksEmail) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: InputDecoration(
                labelText: needsEmail
                    ? _required(strings.emailField)
                    : strings.emailOptionalField,
              ),
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
            ),
          ],
          const SizedBox(height: 8),
          const SignUpErrorText(),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _filled,
            builder: (_, _) => SignUpButton(
              onSubmit: _complete(needsEmail: needsEmail) ? _submit : null,
            ),
          ),
          if (strings.signUpTerms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              strings.signUpTerms,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
