import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/session/presentation/auth_mode.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_backdrop.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_header_scope.dart';
import 'package:tinode_flutter_chat/src/session/presentation/login_sheet.dart';

/// The built-in login screen, shown when the host gave no credentials or
/// its token was rejected: the backdrop with its floating bubbles,
/// the host's `loginHeader` near the top, and the sheet that signs in or
/// up. With the keyboard open, the sheet stays above it, button included,
/// and the header is what scrolls off.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _mode = AuthMode.signIn;

  void _setMode(AuthMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    final header = LoginHeaderScope.maybeOf(context);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: LoginBackdrop()),
          // Reversed, so the scroll view is anchored at its bottom: when the
          // keyboard shrinks it, the sheet and its button stay above the
          // keyboard and the header scrolls off instead. The content is at
          // least as tall as the view, without intrinsic sizes: they would
          // read the form's end size while it animates between modes.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              reverse: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: header == null
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (header != null)
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 56, bottom: 24),
                          child: Center(child: header),
                        ),
                      ),
                    LoginSheet(mode: _mode, onModeChanged: _setMode),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
