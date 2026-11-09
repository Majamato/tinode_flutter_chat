import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One row of a `ChatSheet`: the [icon] in the icon colour on a neutral
/// rounded square, the [label] and an optional [subtitle]. A [destructive]
/// row is in the error colour, on a square of that tint. A tap ticks the
/// haptics, then runs [onTap]. Watches nothing.
class ChatSheetAction extends StatelessWidget {
  const ChatSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final chat = TinodeChatTheme.of(context);
    final iconColor = destructive ? colors.error : chat.iconColor;
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
                        color: destructive
                            ? colors.error.withValues(alpha: 0.12)
                            : colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          icon,
                          size: ChatIconSize.standard,
                          color: iconColor,
                        ),
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
