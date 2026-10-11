import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/change_password_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/progress_button.dart';

/// The new password and, if wanted, a new login. Closes its route with
/// `true` once changed. Watches the change's progress.
class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _password = TextEditingController();
  final _login = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _login.dispose();
    super.dispose();
  }

  void _submit() => unawaited(
    ref
        .read(changePasswordControllerProvider.notifier)
        .submit(password: _password.text, login: _login.text),
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(changePasswordControllerProvider.select((s) => s.value), (
      _,
      done,
    ) {
      if (done ?? false) {
        Navigator.of(context).pop(true);
      }
    });
    final strings = TinodeChatStrings.of(context);
    final busy = ref.watch(
      changePasswordControllerProvider.select((s) => s.isLoading),
    );
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _password,
            decoration: InputDecoration(labelText: strings.newPasswordField),
            autofillHints: const [AutofillHints.newPassword],
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _login,
            decoration: InputDecoration(labelText: strings.newLoginField),
            autofillHints: const [AutofillHints.newUsername],
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          FailureText(failure: ref.watch(changePasswordFailureProvider)),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _password,
            builder: (_, _) => ProgressButton(
              label: strings.changePassword,
              busy: busy,
              onPressed: _password.text.isEmpty ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
