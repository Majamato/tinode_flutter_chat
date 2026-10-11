import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_screen.dart';

/// The login screens' own navigator, starting at the login screen, so the
/// sign-up and password reset screens pushed over it go away as soon as
/// the user is logged in. System back pops it first, then the host's
/// routes.
class AuthNavigator extends StatefulWidget {
  const AuthNavigator({super.key});

  @override
  State<AuthNavigator> createState() => _AuthNavigatorState();
}

class _AuthNavigatorState extends State<AuthNavigator> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => unawaited(_navigator.currentState?.maybePop()),
      child: Navigator(
        key: _navigator,
        onGenerateInitialRoutes: (_, _) => [
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        ],
      ),
    );
  }
}
