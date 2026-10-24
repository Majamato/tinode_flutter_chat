import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/auth_mode.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Sign in | Sign up, 44 px, with a pill that slides under the chosen
/// side on the theme's spring. Watches nothing.
class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  static const _height = 44.0;
  static const _inset = 4.0;

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : chat.springDuration;
    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(chat.fieldRadius),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: mode == AuthMode.signIn
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            duration: duration,
            curve: chat.springCurve,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dark
                      ? theme.colorScheme.outlineVariant
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    chat.fieldRadius - _inset,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (side, label) in [
                (AuthMode.signIn, strings.loginTitle),
                (AuthMode.signUp, strings.signUpTab),
              ])
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: side == mode,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(chat.fieldRadius),
                      onTap: side == mode ? null : () => onChanged(side),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: chat.fadeDuration,
                          style: theme.textTheme.labelLarge!.copyWith(
                            fontSize: 15,
                            color: side == mode
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.outline,
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
