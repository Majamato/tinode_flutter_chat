import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/sign_up_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Opens the sign-up screen, where the host offers it. Watches that
/// choice.
class CreateAccountLink extends ConsumerWidget {
  const CreateAccountLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(signUpOfferedProvider)) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () => unawaited(SignUpScreen.open(context)),
      child: Text(TinodeChatStrings.of(context).createAccountLink),
    );
  }
}
