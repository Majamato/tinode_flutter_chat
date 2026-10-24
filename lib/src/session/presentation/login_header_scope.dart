import 'package:flutter/widgets.dart';

/// Provides the host's `TinodeChat.loginHeader` to the login screen.
class LoginHeaderScope extends InheritedWidget {
  const LoginHeaderScope({
    required this.header,
    required super.child,
    super.key,
  });

  final Widget? header;

  static Widget? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoginHeaderScope>()?.header;

  @override
  bool updateShouldNotify(LoginHeaderScope oldWidget) =>
      header != oldWidget.header;
}
