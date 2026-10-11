import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Explains [failure] in the error colour, under a form; nothing without
/// one.
class FailureText extends StatelessWidget {
  const FailureText({required this.failure, super.key});

  final ChatFailure? failure;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    if (failure == null) {
      return const SizedBox.shrink();
    }
    return Text(
      failureMessage(TinodeChatStrings.of(context), failure),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
