import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Explains [failure] and offers a button that runs [onRetry].
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    required this.failure,
    required this.onRetry,
    this.retryLabel,
    super.key,
  });

  final ChatFailure failure;
  final VoidCallback onRetry;

  /// Defaults to [TinodeChatStrings.retry].
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failureMessage(strings, failure), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(retryLabel ?? strings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
