import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One row of a `ChatSheet`: the [icon] in [tint] (the link colour by
/// default) on a rounded square of the same tint, the [label] and an
/// optional [subtitle]. A [destructive] row is in the error colour. A tap
/// ticks the haptics, then runs [onTap]. Watches nothing.
class ChatSheetAction extends StatelessWidget {
  const ChatSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.tint,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? tint;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chat = TinodeChatTheme.of(context);
    final tint = destructive ? colors.error : this.tint ?? chat.linkColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: _tap,
            borderRadius: BorderRadius.circular(chat.buttonRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(icon, size: 22, color: tint),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: destructive ? colors.error : null,
                            ),
                          ),
                          if (subtitle case final subtitle?)
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tap() {
    unawaited(HapticFeedback.selectionClick());
    onTap();
  }
}
