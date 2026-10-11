import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/password_reset_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Opens the password reset, and says so once the password is set; only
/// where it is offered, which it watches.
class ForgotPasswordLink extends ConsumerWidget {
  const ForgotPasswordLink({super.key});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = TinodeChatStrings.of(context).passwordResetDone;
    if (await PasswordResetScreen.open(context)) {
      messenger.showSnackBar(SnackBar(content: Text(done)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(passwordResetOfferedProvider)) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () => _open(context),
      child: Text(TinodeChatStrings.of(context).forgotPassword),
    );
  }
}
