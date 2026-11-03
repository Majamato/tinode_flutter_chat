import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';

/// Builds the app bar of a [screen] in place of the default one.
///
/// [defaultAppBar] is the bar the chat would show (a `TinodeAppBar`); return
/// it, wrap it, or return your own [PreferredSizeWidget]. The screen's
/// content scrolls under whatever bar you return and starts below its
/// preferred height, so a solid bar works as well as a translucent one.
///
/// ```dart
/// TinodeChat(
///   config: config,
///   appBarBuilder: (context, screen, defaultAppBar) => switch (screen) {
///     TinodeSettingsScreen() => AppBar(title: const Text('Settings')),
///     _ => defaultAppBar,
///   },
/// )
/// ```
typedef TinodeAppBarBuilder =
    PreferredSizeWidget Function(
      BuildContext context,
      TinodeScreen screen,
      PreferredSizeWidget defaultAppBar,
    );

/// Provides the host's [TinodeAppBarBuilder] to the screens.
class AppBarBuilderScope extends InheritedWidget {
  const AppBarBuilderScope({
    required this.builder,
    required super.child,
    super.key,
  });

  final TinodeAppBarBuilder? builder;

  static TinodeAppBarBuilder? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppBarBuilderScope>()?.builder;

  @override
  bool updateShouldNotify(AppBarBuilderScope oldWidget) =>
      builder != oldWidget.builder;
}
