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
    required this.missedCallColor,
    required this.readReceiptColor,
    required this.senderNameColors,
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
      missedCallColor: colors.error,
      readReceiptColor: colors.primary,
      senderNameColors: [
        for (final swatch in _senderSwatches)
          theme.brightness == Brightness.dark
              ? swatch.shade300
              : swatch.shade700,
      ],
    );
  }

  /// The chat theme of the nearest [Theme], or one derived from it.
  factory TinodeChatTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TinodeChatTheme>() ??
        TinodeChatTheme.fallback(theme);
  }

  static const List<MaterialColor> _senderSwatches = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.brown,
  ];

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

  /// Icon and status of calls that did not happen: missed, declined or
  /// not connected.
  final Color missedCallColor;

  /// The ticks of one of the user's messages that every other member read.
  final Color readReceiptColor;

  /// Sender names in groups; each member keeps one of these, picked from
  /// their user ID. Must not be empty.
  final List<Color> senderNameColors;

  /// The colour of the member [colorIndex] names, from [senderNameColors].
  Color senderNameColor(int colorIndex) =>
      senderNameColors[colorIndex % senderNameColors.length];

  @override
  TinodeChatTheme copyWith({
    Color? ownBubbleColor,
    Color? onOwnBubbleColor,
    Color? peerBubbleColor,
    Color? onPeerBubbleColor,
    double? bubbleRadius,
    Color? unreadBadgeColor,
    Color? onUnreadBadgeColor,
    Color? missedCallColor,
    Color? readReceiptColor,
    List<Color>? senderNameColors,
  }) => TinodeChatTheme(
    ownBubbleColor: ownBubbleColor ?? this.ownBubbleColor,
    onOwnBubbleColor: onOwnBubbleColor ?? this.onOwnBubbleColor,
    peerBubbleColor: peerBubbleColor ?? this.peerBubbleColor,
    onPeerBubbleColor: onPeerBubbleColor ?? this.onPeerBubbleColor,
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    unreadBadgeColor: unreadBadgeColor ?? this.unreadBadgeColor,
    onUnreadBadgeColor: onUnreadBadgeColor ?? this.onUnreadBadgeColor,
    missedCallColor: missedCallColor ?? this.missedCallColor,
    readReceiptColor: readReceiptColor ?? this.readReceiptColor,
    senderNameColors: senderNameColors ?? this.senderNameColors,
  );

  @override
  TinodeChatTheme lerp(TinodeChatTheme? other, double t) {
    if (other == null) {
      return this;
    }
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
      missedCallColor: Color.lerp(missedCallColor, other.missedCallColor, t)!,
      readReceiptColor: Color.lerp(
        readReceiptColor,
        other.readReceiptColor,
        t,
      )!,
      senderNameColors: senderNameColors.length == other.senderNameColors.length
          ? [
              for (var i = 0; i < senderNameColors.length; i++)
                Color.lerp(senderNameColors[i], other.senderNameColors[i], t)!,
            ]
          : (t < 0.5 ? senderNameColors : other.senderNameColors),
    );
  }
}
