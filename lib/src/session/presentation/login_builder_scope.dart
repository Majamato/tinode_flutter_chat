import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/session/presentation/tinode_login_view.dart';

/// Builds the login screen in place of the default one.
///
/// The result is the body of the screen's `Scaffold`. Draw what you like
/// around [TinodeLoginView.form], which does the work. [defaultLogin] is the
/// plain screen the chat would show; wrap it, or ignore it.
///
/// ```dart
/// TinodeChat(
///   config: config,
///   loginBuilder: (context, login, defaultLogin) => Center(
///     child: MyCard(child: login.form),
///   ),
/// )
/// ```
typedef TinodeLoginBuilder =
    Widget Function(
      BuildContext context,
      TinodeLoginView login,
      Widget defaultLogin,
    );

/// Provides the host's [TinodeLoginBuilder] to the login screen.
class LoginBuilderScope extends InheritedWidget {
  const LoginBuilderScope({
    required this.builder,
    required super.child,
    super.key,
  });

  final TinodeLoginBuilder? builder;

  static TinodeLoginBuilder? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoginBuilderScope>()?.builder;

  @override
  bool updateShouldNotify(LoginBuilderScope oldWidget) =>
      builder != oldWidget.builder;
}
