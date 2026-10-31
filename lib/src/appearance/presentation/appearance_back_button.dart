import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// "‹ [label]" in the link colour: back to the screen named [label].
/// Watches nothing.
class AppearanceBackButton extends StatelessWidget {
  const AppearanceBackButton({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = TinodeChatTheme.of(context).linkColor;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, size: 30, color: color),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
