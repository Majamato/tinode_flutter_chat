import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A group of settings: an optional upper-case [title], then [children] on
/// a card with dividers between them, then an optional [footer] that
/// explains them. Watches nothing.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.children,
    this.title,
    this.footer,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String? title;
  final List<Widget> children;
  final String? footer;

  /// Around [children], inside the card.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final muted = theme.colorScheme.outline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final title?) SettingsLabel(title),
        DecoratedBox(
          decoration: BoxDecoration(
            color: chat.cardColor,
            borderRadius: BorderRadius.circular(chat.cardRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(chat.cardRadius),
            child: Padding(
              padding: padding,
              child: Column(
                children: [
                  for (final (index, child) in children.indexed) ...[
                    if (index > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    child,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (footer case final footer?)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              footer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted,
                height: 1.45,
              ),
            ),
          ),
      ],
    );
  }
}
