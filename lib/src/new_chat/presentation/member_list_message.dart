import 'package:flutter/material.dart';

/// A short muted line in the add members list, in place of rows: how to
/// find people, or that nobody was found. Watches nothing.
class MemberListMessage extends StatelessWidget {
  const MemberListMessage(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
