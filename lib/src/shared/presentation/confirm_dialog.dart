import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Asks before an action that can't be undone: [message], with Cancel and
/// a button labelled [action].
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({required this.message, required this.action, super.key});

  /// Shows the dialog; true when the user confirmed.
  static Future<bool> ask(
    BuildContext context, {
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => ConfirmDialog(message: message, action: action),
      ) ??
      false;

  final String message;
  final String action;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(action),
        ),
      ],
    );
  }
}
