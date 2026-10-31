import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/app/presentation/tinode_appearance.dart';

/// Provides the host's `TinodeChat.appearance` and `appearanceExtra` to the
/// settings, rebuilding what reads them when the user picks another look.
class AppearanceScope extends InheritedNotifier<TinodeAppearance> {
  const AppearanceScope({
    required TinodeAppearance? appearance,
    required this.extra,
    required super.child,
    super.key,
  }) : super(notifier: appearance);

  final Widget? extra;

  /// The host's appearance; null when it offers none.
  static TinodeAppearance? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;

  /// The host's appearance, without rebuilding when the user picks
  /// another look: for what never changes, e.g. the palettes on offer.
  static TinodeAppearance? peek(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppearanceScope>()?.notifier;

  /// The host's widget for the appearance screen, if any.
  static Widget? extraOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.extra;

  @override
  bool updateShouldNotify(AppearanceScope oldWidget) =>
      notifier != oldWidget.notifier || extra != oldWidget.extra;
}
