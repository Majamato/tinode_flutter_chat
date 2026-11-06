import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_auth_mode.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_header_scope.dart';
import 'package:tinode_flutter_chat/src/session/presentation/tinode_login_view.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The plain login screen, when the host draws none: the host's
/// `loginHeader`, a title, the form, and a button to the other side where
/// sign-up is offered, centred. With the keyboard open, the form stays above
/// it, button included, and the header is what scrolls off. Watches nothing.
class DefaultLogin extends StatelessWidget {
  const DefaultLogin({required this.login, super.key});

  final TinodeLoginView login;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    final header = LoginHeaderScope.maybeOf(context);
    final signIn = login.mode == TinodeAuthMode.signIn;
    return SafeArea(
      // Reversed, so the scroll view is anchored at its bottom: when the
      // keyboard shrinks it, the button stays above the keyboard.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          reverse: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null) ...[
                        Center(child: header),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        signIn ? strings.loginHeadline : strings.signUpHeadline,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signIn ? strings.loginSubtitle : strings.signUpSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 24),
                      login.form,
                      if (login.signUpOffered) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => login.onModeChanged(
                            signIn
                                ? TinodeAuthMode.signUp
                                : TinodeAuthMode.signIn,
                          ),
                          child: Text(
                            signIn ? strings.signUpTab : strings.loginTitle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
