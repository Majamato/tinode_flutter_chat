import 'package:flutter/widgets.dart';

/// Provides the host's `TinodeChat.tabBar` to the chat's navigator.
class ShellScope extends InheritedWidget {
  const ShellScope({required this.tabBar, required super.child, super.key});

  final bool tabBar;

  /// Whether the chat shows its tab bar; false outside a `TinodeChat`.
  static bool tabBarOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.tabBar ?? false;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => tabBar != oldWidget.tabBar;
}
