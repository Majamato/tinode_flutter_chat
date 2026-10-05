import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/login_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The login button; the only widget that rebuilds while a login runs.
class LoginSubmitButton extends ConsumerWidget {
  const LoginSubmitButton({required this.onSubmit, super.key});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      loginControllerProvider.select((s) => s.isLoading),
    );
    return FilledButton(
      onPressed: loading ? null : onSubmit,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(TinodeChatStrings.of(context).signIn),
    );
  }
}
