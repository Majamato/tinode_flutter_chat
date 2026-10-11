import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/password_reset_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/password_reset_state.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/progress_button.dart';

/// The email field, then, once a code went out, the code and new password
/// fields. Closes its route with `true` once the password is set. Watches
/// the reset's progress.
class PasswordResetForm extends ConsumerStatefulWidget {
  const PasswordResetForm({super.key});

  @override
  ConsumerState<PasswordResetForm> createState() => _PasswordResetFormState();
}

class _PasswordResetFormState extends ConsumerState<PasswordResetForm> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  PasswordResetController get _controller =>
      ref.read(passwordResetControllerProvider.notifier);

  void _request() {
    if (_email.text.trim().isNotEmpty) {
      unawaited(_controller.request(_email.text));
    }
  }

  void _reset() {
    if (_code.text.trim().isNotEmpty && _password.text.isNotEmpty) {
      unawaited(_controller.reset(code: _code.text, password: _password.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(passwordResetControllerProvider.select((s) => s.done), (
      _,
      done,
    ) {
      if (done) {
        Navigator.of(context).pop(true);
      }
    });
    final strings = TinodeChatStrings.of(context);
    final PasswordResetState(:codeSent, :busy, :failure) = ref.watch(
      passwordResetControllerProvider,
    );
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            decoration: InputDecoration(labelText: strings.emailField),
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enabled: !codeSent,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _request(),
          ),
          if (codeSent) ...[
            const SizedBox(height: 12),
            Text(strings.resetCodeSent),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: InputDecoration(labelText: strings.resetCodeField),
              autofillHints: const [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: InputDecoration(labelText: strings.newPasswordField),
              autofillHints: const [AutofillHints.newPassword],
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _reset(),
            ),
          ],
          const SizedBox(height: 8),
          FailureText(failure: failure),
          const SizedBox(height: 16),
          ProgressButton(
            label: codeSent ? strings.setPassword : strings.sendResetCode,
            busy: busy,
            onPressed: codeSent ? _reset : _request,
          ),
        ],
      ),
    );
  }
}
