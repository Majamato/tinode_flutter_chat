import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/progress_button.dart';

/// The sign-up button; watches whether a sign-up runs.
class SignUpButton extends ConsumerWidget {
  const SignUpButton({required this.onSubmit, super.key});

  /// Null while the form is incomplete.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProgressButton(
      label: TinodeChatStrings.of(context).signUp,
      busy: ref.watch(signUpControllerProvider.select((s) => s.isLoading)),
      onPressed: onSubmit,
    );
  }
}
