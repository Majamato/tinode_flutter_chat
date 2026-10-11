import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/confirm_email_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/progress_button.dart';

/// The code field and its button. Watches the confirmation's progress.
class ConfirmEmailForm extends ConsumerStatefulWidget {
  const ConfirmEmailForm({
    required this.login,
    required this.password,
    super.key,
  });

  final String login;
  final String password;

  @override
  ConsumerState<ConfirmEmailForm> createState() => _ConfirmEmailFormState();
}

class _ConfirmEmailFormState extends ConsumerState<ConfirmEmailForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _confirm() => unawaited(
    ref
        .read(confirmEmailControllerProvider.notifier)
        .confirm(
          login: widget.login,
          password: widget.password,
          code: _code.text,
        ),
  );

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final busy = ref.watch(
      confirmEmailControllerProvider.select((s) => s.isLoading),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.confirmEmailText),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          decoration: InputDecoration(labelText: strings.resetCodeField),
          autofillHints: const [AutofillHints.oneTimeCode],
          keyboardType: TextInputType.number,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _confirm(),
        ),
        const SizedBox(height: 8),
        FailureText(failure: ref.watch(confirmEmailFailureProvider)),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: _code,
          builder: (_, _) => ProgressButton(
            label: strings.confirm,
            busy: busy,
            onPressed: _code.text.trim().isEmpty ? null : _confirm,
          ),
        ),
      ],
    );
  }
}
