import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_sheet.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Asks before an action that can't be undone, as a sheet opened by
/// [showChatSheet]: the [icon] on a circle in the error tint, the [title],
/// the [message] under it, then a full-width button labelled [action] in
/// the error colour over a neutral Cancel. A text taller than the sheet
/// may be scrolls, and the buttons stay in view. Watches nothing.
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    super.key,
  });

  /// Opens the sheet; true when the user confirmed, false when they
  /// cancelled or dismissed it.
  static Future<bool> ask(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String action,
  }) async =>
      await showChatSheet<bool>(
        context,
        builder: (_) => ConfirmSheet(
          icon: icon,
          title: title,
          message: message,
          action: action,
        ),
      ) ??
      false;

  final IconData icon;
  final String title;
  final String message;
  final String action;

  void _confirm(BuildContext context) {
    unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pop(true);
  }

  void _cancel(BuildContext context) => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _Badge(icon: icon)),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _confirm(context),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: Text(action),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _cancel(context),
              style: FilledButton.styleFrom(
                backgroundColor: colors.surfaceContainer,
                foregroundColor: colors.onSurface,
              ),
              child: Text(TinodeChatStrings.of(context).cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 56,
          child: Icon(icon, size: ChatIconSize.large, color: error),
        ),
      ),
    );
  }
}
