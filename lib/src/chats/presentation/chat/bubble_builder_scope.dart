import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/chats/domain/tinode_bubble.dart';

/// Builds the bubble of a message in place of the default one.
///
/// [defaultBubble] is the bubble the chat would show, with its tail, gestures
/// and status; wrap it, or return your own widget built from [bubble].
///
/// ```dart
/// TinodeChat(
///   config: config,
///   bubbleBuilder: (context, bubble, defaultBubble) => bubble.own
///       ? defaultBubble
///       : Opacity(opacity: 0.9, child: defaultBubble),
/// )
/// ```
typedef TinodeBubbleBuilder =
    Widget Function(
      BuildContext context,
      TinodeBubble bubble,
      Widget defaultBubble,
    );

/// Provides the host's [TinodeBubbleBuilder] to the bubbles.
class BubbleBuilderScope extends InheritedWidget {
  const BubbleBuilderScope({
    required this.builder,
    required super.child,
    super.key,
  });

  final TinodeBubbleBuilder? builder;

  static TinodeBubbleBuilder? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BubbleBuilderScope>()?.builder;

  @override
  bool updateShouldNotify(BubbleBuilderScope oldWidget) =>
      builder != oldWidget.builder;
}
