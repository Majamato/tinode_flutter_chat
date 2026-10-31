import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/auth_mode.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/sliding_segments.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Sign in | Sign up, 44 px, with a pill that slides under the chosen
/// side on the theme's spring. Watches nothing.
class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SlidingSegments(
      segments: [
        (AuthMode.signIn, strings.loginTitle),
        (AuthMode.signUp, strings.signUpTab),
      ],
      selected: mode,
      onChanged: onChanged,
      height: 44,
      radius: TinodeChatTheme.of(context).fieldRadius,
      trackColor: colors.surfaceContainer,
      pillColor: theme.brightness == Brightness.dark
          ? colors.outlineVariant
          : colors.surface,
      pillShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      labelColor: colors.outline,
      selectedLabelColor: colors.onSurface,
    );
  }
}
