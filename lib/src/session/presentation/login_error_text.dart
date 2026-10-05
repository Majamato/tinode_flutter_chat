import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/login_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Why the last login failed, if it did.
class LoginErrorText extends ConsumerWidget {
  const LoginErrorText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = ref.watch(loginFailureProvider);
    if (failure == null) return const SizedBox.shrink();
    return Text(
      failureMessage(TinodeChatStrings.of(context), failure),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
