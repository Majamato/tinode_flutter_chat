import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';

/// Provides the host's [TinodeChatIcons] to the chat's widgets.
class TinodeChatIconsScope extends InheritedWidget {
  const TinodeChatIconsScope({
    required this.icons,
    required super.child,
    super.key,
  });

  final TinodeChatIcons icons;

  static TinodeChatIcons? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TinodeChatIconsScope>()?.icons;

  @override
  bool updateShouldNotify(TinodeChatIconsScope oldWidget) =>
      icons != oldWidget.icons;
}
