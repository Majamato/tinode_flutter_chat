import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/account/application/change_password_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/password_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/progress_button.dart';

/// The new password, then the same again; the button sends it once both
/// match. Closes its route with `true` once changed. Watches the change's
/// progress.
class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final _fields = Listenable.merge([_password, _confirm]);

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready =>
      _password.text.isNotEmpty && _password.text == _confirm.text;

  void _submit() {
    if (_ready) {
      unawaited(
        ref
            .read(changePasswordControllerProvider.notifier)
            .submit(password: _password.text),
      );
    }
  }

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
          PasswordField(
            controller: _password,
            label: strings.newPasswordField,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _fields,
            builder: (_, _) => PasswordField(
              controller: _confirm,
              label: strings.confirmNewPasswordField,
              autofillHints: const [AutofillHints.newPassword],
              errorText:
                  _confirm.text.isNotEmpty && _confirm.text != _password.text
                  ? strings.passwordsDontMatch
                  : null,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 8),
          FailureText(failure: ref.watch(changePasswordFailureProvider)),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _fields,
            builder: (_, _) => ProgressButton(
              label: strings.changePassword,
              busy: busy,
              onPressed: _ready ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}
