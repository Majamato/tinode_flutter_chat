import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// One row of a `SettingsSection`: [leading] (or an [icon] in the link
/// colour), the [title] and an optional [subtitle], and a chevron when it
/// opens a screen, or a [trailing] widget, such as a switch, in its place.
/// A [destructive] row is in the error colour, without a chevron. Watches
/// nothing.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    required this.onTap,
    this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    this.minHeight = 52,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// At the end of the row instead of the chevron.
  final Widget? trailing;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool destructive;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = destructive
        ? colors.error
        : TinodeChatTheme.of(context).linkColor;
    final icon = this.icon;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (leading case final leading?)
                leading
              else if (icon != null)
                Icon(icon, color: color),
              if (leading != null || icon != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
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
              if (trailing case final trailing?)
                trailing
              else if (!destructive && onTap != null)
                Icon(
                  TinodeChatIcons.of(context).disclosure,
                  color: colors.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
