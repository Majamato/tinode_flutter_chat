import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colors and shapes of the chat widgets.
///
/// Add one to your app's `ThemeData.extensions` to restyle the chat; any
/// `TinodeChat` without one derives it from the color scheme with
/// [TinodeChatTheme.fallback].
@immutable
class TinodeChatTheme extends ThemeExtension<TinodeChatTheme> {
  /// Creates a chat theme with every value given.
  const TinodeChatTheme({
    required this.ownBubbleColor,
    required this.onOwnBubbleColor,
    required this.peerBubbleColor,
    required this.onPeerBubbleColor,
    required this.bubbleRadius,
    required this.unreadBadgeColor,
    required this.onUnreadBadgeColor,
  });

  /// A chat theme derived from [theme]'s color scheme.
  factory TinodeChatTheme.fallback(ThemeData theme) {
    final colors = theme.colorScheme;
    return TinodeChatTheme(
      ownBubbleColor: colors.primaryContainer,
      onOwnBubbleColor: colors.onPrimaryContainer,
      peerBubbleColor: colors.surfaceContainerHighest,
      onPeerBubbleColor: colors.onSurface,
      bubbleRadius: 16,
      unreadBadgeColor: colors.primary,
      onUnreadBadgeColor: colors.onPrimary,
    );
  }

  /// The chat theme of the nearest [Theme], or one derived from it.
  factory TinodeChatTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TinodeChatTheme>() ??
        TinodeChatTheme.fallback(theme);
  }

  /// Background of the user's own messages.
  final Color ownBubbleColor;

  /// Text on [ownBubbleColor].
  final Color onOwnBubbleColor;

  /// Background of other users' messages.
  final Color peerBubbleColor;

  /// Text on [peerBubbleColor].
  final Color onPeerBubbleColor;

  /// Corner radius of message bubbles.
  final double bubbleRadius;

  /// Background of the unread counter in the chat list.
  final Color unreadBadgeColor;

  /// Text on [unreadBadgeColor].
  final Color onUnreadBadgeColor;

  @override
  TinodeChatTheme copyWith({
    Color? ownBubbleColor,
    Color? onOwnBubbleColor,
    Color? peerBubbleColor,
    Color? onPeerBubbleColor,
    double? bubbleRadius,
    Color? unreadBadgeColor,
    Color? onUnreadBadgeColor,
  }) => TinodeChatTheme(
    ownBubbleColor: ownBubbleColor ?? this.ownBubbleColor,
    onOwnBubbleColor: onOwnBubbleColor ?? this.onOwnBubbleColor,
    peerBubbleColor: peerBubbleColor ?? this.peerBubbleColor,
    onPeerBubbleColor: onPeerBubbleColor ?? this.onPeerBubbleColor,
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    unreadBadgeColor: unreadBadgeColor ?? this.unreadBadgeColor,
    onUnreadBadgeColor: onUnreadBadgeColor ?? this.onUnreadBadgeColor,
  );

  @override
  TinodeChatTheme lerp(TinodeChatTheme? other, double t) {
    if (other == null) return this;
    return TinodeChatTheme(
      ownBubbleColor: Color.lerp(ownBubbleColor, other.ownBubbleColor, t)!,
      onOwnBubbleColor: Color.lerp(
        onOwnBubbleColor,
        other.onOwnBubbleColor,
        t,
      )!,
      peerBubbleColor: Color.lerp(peerBubbleColor, other.peerBubbleColor, t)!,
      onPeerBubbleColor: Color.lerp(
        onPeerBubbleColor,
        other.onPeerBubbleColor,
        t,
      )!,
      bubbleRadius: lerpDouble(bubbleRadius, other.bubbleRadius, t)!,
      unreadBadgeColor: Color.lerp(
        unreadBadgeColor,
        other.unreadBadgeColor,
        t,
      )!,
      onUnreadBadgeColor: Color.lerp(
        onUnreadBadgeColor,
        other.onUnreadBadgeColor,
        t,
      )!,
    );
  }
}
