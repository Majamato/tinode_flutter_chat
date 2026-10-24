import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// What a [CallRoundButton] looks like.
enum CallButtonStyle {
  /// Translucent glass; white when [CallRoundButton.active].
  glass,

  /// Red with a red glow: ending or declining the call.
  danger,

  /// Green: accepting the call.
  accept,
}

/// A round button of the call screens, with an optional [label] below it
/// that is part of the button. A toggle passes [active], which screen
/// readers announce, and turns white with a dark icon while on.
class CallRoundButton extends StatelessWidget {
  const CallRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
    this.active,
    this.style = CallButtonStyle.glass,
    this.size = 64,
    super.key,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? label;

  /// Whether the toggle is on; null for a button that isn't a toggle.
  final bool? active;
  final CallButtonStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final danger = Theme.of(context).colorScheme.error;
    final on = active ?? false;
    final background = switch (style) {
      CallButtonStyle.glass =>
        on ? theme.callControlActiveColor : theme.callControlColor,
      CallButtonStyle.danger => danger,
      CallButtonStyle.accept => theme.acceptCallColor,
    };
    final foreground = on && style == CallButtonStyle.glass
        ? theme.onCallControlActiveColor
        : theme.onCallColor;
    final circle = AnimatedContainer(
      duration: theme.fadeDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        boxShadow: style == CallButtonStyle.danger
            ? [
                BoxShadow(
                  color: danger,
                  offset: const Offset(0, 12),
                  blurRadius: 26,
                  spreadRadius: -10,
                ),
              ]
            : null,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground, size: 26),
        child: Center(child: icon),
      ),
    );
    final label = this.label;
    return Semantics(
      button: true,
      toggled: active,
      excludeSemantics: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: onPressed,
          behavior: HitTestBehavior.opaque,
          child: label == null
              ? circle
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    circle,
                    const SizedBox(height: 8),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.onCallColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
