import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/session/presentation/auth_mode.dart';
import 'package:tinode_flutter_chat/src/session/presentation/auth_mode_switch.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_form.dart';
import 'package:tinode_flutter_chat/src/session/presentation/sign_up_form.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The sheet at the bottom of the login screen: a title for [mode], the
/// switch between signing in and up where the host offers sign-up (which
/// it watches), and the form for [mode]. It rises 60 px into place as it
/// fades in; with Reduce motion it only fades. Switching forms cross-fades
/// in 320 ms, and only one form is ever in the tree.
class LoginSheet extends ConsumerStatefulWidget {
  const LoginSheet({
    required this.mode,
    required this.onModeChanged,
    super.key,
  });

  static const _rise = Duration(milliseconds: 550);
  static const _switch = Duration(milliseconds: 320);

  final AuthMode mode;
  final ValueChanged<AuthMode> onModeChanged;

  @override
  ConsumerState<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<LoginSheet>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: LoginSheet._rise,
  );
  CurvedAnimation? _rise;
  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rise?.dispose();
    _rise = CurvedAnimation(
      parent: _controller,
      curve: TinodeChatTheme.of(context).springCurve,
    );
    _still = MediaQuery.disableAnimationsOf(context);
    if (_controller.isDismissed) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _rise?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final theme = Theme.of(context);
    final chat = TinodeChatTheme.of(context);
    final signUpOffered = ref.watch(signUpOfferedProvider);
    final mode = signUpOffered ? widget.mode : AuthMode.signIn;
    final signIn = mode == AuthMode.signIn;
    final rise = _rise!;
    final form = signIn
        ? const LoginForm(key: ValueKey(AuthMode.signIn))
        : const SignUpForm(key: ValueKey(AuthMode.signUp));
    return FadeTransition(
      opacity: _controller,
      child: AnimatedBuilder(
        animation: rise,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _still ? 0 : 60 * (1 - rise.value)),
          child: child,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(chat.sheetRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 50,
                spreadRadius: -30,
                offset: const Offset(0, -20),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        signIn ? strings.loginHeadline : strings.signUpHeadline,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        signIn ? strings.loginSubtitle : strings.signUpSubtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (signUpOffered) ...[
                        AuthModeSwitch(
                          mode: mode,
                          onChanged: widget.onModeChanged,
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (_still)
                        form
                      else
                        AnimatedSize(
                          duration: LoginSheet._switch,
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: LoginSheet._switch,
                            layoutBuilder: (current, _) => current!,
                            child: form,
                          ),
                        ),
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
