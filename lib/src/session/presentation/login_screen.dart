import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_auth_mode.dart';
import 'package:tinode_flutter_chat/src/session/presentation/default_login.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_builder_scope.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_form.dart';
import 'package:tinode_flutter_chat/src/session/presentation/sign_up_form.dart';
import 'package:tinode_flutter_chat/src/session/presentation/tinode_login_view.dart';

/// The login screen, shown when the host gave no credentials or its token
/// was rejected. It holds the side the user is on and offers the form for
/// it, in the host's `loginBuilder` or, without one, in [DefaultLogin].
/// Only one form is ever in the tree. Watches whether sign-up is offered.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  TinodeAuthMode _mode = TinodeAuthMode.signIn;

  void _setMode(TinodeAuthMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    final signUpOffered = ref.watch(signUpOfferedProvider);
    final mode = signUpOffered ? _mode : TinodeAuthMode.signIn;
    final login = TinodeLoginView(
      mode: mode,
      onModeChanged: _setMode,
      signUpOffered: signUpOffered,
      form: mode == TinodeAuthMode.signIn
          ? const LoginForm(key: ValueKey(TinodeAuthMode.signIn))
          : const SignUpForm(key: ValueKey(TinodeAuthMode.signUp)),
    );
    final defaultLogin = DefaultLogin(login: login);
    final builder = LoginBuilderScope.maybeOf(context);
    return Scaffold(
      body: builder == null
          ? defaultLogin
          : builder(context, login, defaultLogin),
    );
  }
}
