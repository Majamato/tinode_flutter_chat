import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_material_theme.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_neutrals.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_palette.dart';

/// Colors, shapes and motion of the chat widgets.
///
/// Add one to your app's `ThemeData.extensions` to restyle the chat; any
/// `TinodeChat` without one derives it from the color scheme with
/// [TinodeChatTheme.fallback]. [TinodeChatTheme.materialTheme] builds a
/// whole `ThemeData` in the chat's design from a [TinodeChatPalette].
@immutable
class TinodeChatTheme extends ThemeExtension<TinodeChatTheme> {
  /// Creates a chat theme with every value given.
  const TinodeChatTheme({
    required this.ownBubbleColor,
    required this.onOwnBubbleColor,
    required this.ownMetaColor,
    required this.peerBubbleColor,
    required this.onPeerBubbleColor,
    required this.peerMetaColor,
    required this.bubbleRadius,
    required this.bubbleTail,
    required this.photoRadius,
    required this.sameRunGap,
    required this.newRunGap,
    required this.wallpaperColor,
    required this.wallpaperDotColor,
    required this.dateChipColor,
    required this.glassColor,
    required this.glassEdgeColor,
    required this.linkColor,
    required this.unreadBadgeColor,
    required this.onUnreadBadgeColor,
    required this.mutedBadgeColor,
    required this.onlineColor,
    required this.missedCallColor,
    required this.readReceiptColor,
    required this.waveOffColor,
    required this.senderNameColors,
    required this.revealedMessageColor,
    required this.composerRadius,
    required this.fieldRadius,
    required this.buttonRadius,
    required this.sheetRadius,
    required this.springCurve,
    required this.springDuration,
    required this.fadeDuration,
  });

  /// A chat theme derived from [theme]'s color scheme.
  factory TinodeChatTheme.fallback(ThemeData theme) {
    final colors = theme.colorScheme;
    return TinodeChatTheme(
      ownBubbleColor: colors.primaryContainer,
      onOwnBubbleColor: colors.onPrimaryContainer,
      ownMetaColor: colors.onPrimaryContainer.withValues(alpha: 0.7),
      peerBubbleColor: colors.surfaceContainerHighest,
      onPeerBubbleColor: colors.onSurface,
      peerMetaColor: colors.onSurface.withValues(alpha: 0.7),
      bubbleRadius: 16,
      bubbleTail: false,
      photoRadius: 8,
      sameRunGap: 2,
      newRunGap: 2,
      wallpaperColor: colors.surface,
      wallpaperDotColor: Colors.transparent,
      dateChipColor: colors.scrim.withValues(alpha: 0.34),
      glassColor: colors.surface,
      glassEdgeColor: colors.outlineVariant,
      linkColor: colors.primary,
      unreadBadgeColor: colors.primary,
      onUnreadBadgeColor: colors.onPrimary,
      mutedBadgeColor: colors.outline,
      onlineColor: ChatNeutrals.online,
      missedCallColor: colors.error,
      readReceiptColor: colors.primary,
      waveOffColor: colors.outlineVariant,
      senderNameColors: _senderNameColors(theme.brightness),
      revealedMessageColor: colors.primary.withValues(alpha: 0.16),
      composerRadius: 22,
      fieldRadius: 4,
      buttonRadius: 20,
      sheetRadius: 28,
      springCurve: Curves.easeOutCubic,
      springDuration: const Duration(milliseconds: 300),
      fadeDuration: const Duration(milliseconds: 200),
    );
  }

  /// The chat's own design in [palette]'s colors. In dark mode `night`
  /// takes the place of `primary`, and `onDark` that of `ink`.
  factory TinodeChatTheme.fromPalette(
    TinodeChatPalette palette, {
    Brightness brightness = Brightness.light,
  }) {
    final dark = brightness == Brightness.dark;
    final neutrals = ChatNeutrals.of(brightness);
    final primary = dark ? palette.night : palette.primary;
    const onPrimary = Color(0xFFFFFFFF);
    return TinodeChatTheme(
      ownBubbleColor: primary,
      onOwnBubbleColor: onPrimary,
      ownMetaColor: onPrimary.withValues(alpha: 0.85),
      peerBubbleColor: neutrals.peerBubble,
      onPeerBubbleColor: neutrals.text,
      peerMetaColor: neutrals.muted,
      bubbleRadius: 20,
      bubbleTail: true,
      photoRadius: 15,
      sameRunGap: 2,
      newRunGap: 12,
      wallpaperColor: dark ? neutrals.page : palette.soft,
      wallpaperDotColor: dark
          ? const Color(0x12FFFFFF)
          : palette.primary.withValues(alpha: 0.13),
      dateChipColor: neutrals.dateChip,
      glassColor: neutrals.glass,
      glassEdgeColor: neutrals.glassEdge,
      linkColor: dark ? palette.onDark : palette.ink,
      unreadBadgeColor: primary,
      onUnreadBadgeColor: onPrimary,
      mutedBadgeColor: neutrals.mutedBadge,
      onlineColor: ChatNeutrals.online,
      missedCallColor: ChatNeutrals.danger,
      readReceiptColor: onPrimary,
      waveOffColor: neutrals.waveOff,
      senderNameColors: _senderNameColors(brightness),
      revealedMessageColor: primary.withValues(alpha: 0.16),
      composerRadius: 22,
      fieldRadius: 14,
      buttonRadius: 16,
      sheetRadius: 28,
      springCurve: const Cubic(0.2, 0.9, 0.3, 1.25),
      springDuration: const Duration(milliseconds: 380),
      fadeDuration: const Duration(milliseconds: 200),
    );
  }

  /// The chat theme of the nearest [Theme], or one derived from it.
  factory TinodeChatTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TinodeChatTheme>() ??
        TinodeChatTheme.fallback(theme);
  }

  /// A whole app theme in the chat's design, in [palette]'s colors (the
  /// neutral one by default): colors, text styles from the chat's type
  /// scale, inputs, buttons, app bars and sheets, and the matching
  /// [TinodeChatTheme.fromPalette] as an extension.
  ///
  /// [fontFamily] sets the interface's font and [displayFontFamily] that
  /// of the display styles, for big and rare headlines; the app bundles
  /// both. Change any part with `copyWith`.
  ///
  /// ```dart
  /// MaterialApp(
  ///   theme: TinodeChatTheme.materialTheme(fontFamily: 'Inter'),
  ///   darkTheme: TinodeChatTheme.materialTheme(
  ///     brightness: Brightness.dark,
  ///     fontFamily: 'Inter',
  ///   ),
  /// )
  /// ```
  static ThemeData materialTheme({
    TinodeChatPalette palette = TinodeChatPalette.neutral,
    Brightness brightness = Brightness.light,
    String? fontFamily,
    String? displayFontFamily,
  }) => chatMaterialTheme(
    palette: palette,
    brightness: brightness,
    fontFamily: fontFamily,
    displayFontFamily: displayFontFamily,
  );

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

  static List<Color> _senderNameColors(Brightness brightness) => [
    for (final swatch in _senderSwatches)
      brightness == Brightness.dark ? swatch.shade300 : swatch.shade700,
  ];

  /// Background of the user's own messages.
  final Color ownBubbleColor;

  /// Text on [ownBubbleColor].
  final Color onOwnBubbleColor;

  /// The time and ticks on [ownBubbleColor].
  final Color ownMetaColor;

  /// Background of other users' messages.
  final Color peerBubbleColor;

  /// Text on [peerBubbleColor].
  final Color onPeerBubbleColor;

  /// The time on [peerBubbleColor].
  final Color peerMetaColor;

  /// Corner radius of message bubbles.
  final double bubbleRadius;

  /// Whether the last bubble of a run has a tail at its bottom corner.
  final bool bubbleTail;

  /// Corner radius of photos and file tiles in a bubble.
  final double photoRadius;

  /// Space between two bubbles of one run.
  final double sameRunGap;

  /// Space between two runs.
  final double newRunGap;

  /// Behind the messages of a chat.
  final Color wallpaperColor;

  /// The dot pattern on [wallpaperColor]; transparent for none.
  final Color wallpaperDotColor;

  /// Behind the date between messages, under white text.
  final Color dateChipColor;

  /// Frosted bars: headers, the composer, the tab bar.
  final Color glassColor;

  /// The edge between a frosted bar and what scrolls under it.
  final Color glassEdgeColor;

  /// Links and text buttons in the brand's hue.
  final Color linkColor;

  /// Background of the unread counter in the chat list.
  final Color unreadBadgeColor;

  /// Text on [unreadBadgeColor] and [mutedBadgeColor].
  final Color onUnreadBadgeColor;

  /// Background of the unread counter of a muted chat.
  final Color mutedBadgeColor;

  /// The dot of someone online.
  final Color onlineColor;

  /// Icon and status of calls that did not happen: missed, declined or
  /// not connected.
  final Color missedCallColor;

  /// The ticks of one of the user's messages that every other member read.
  final Color readReceiptColor;

  /// The unplayed part of a voice message's waveform.
  final Color waveOffColor;

  /// Sender names in groups; each member keeps one of these, picked from
  /// their user ID. Must not be empty.
  final List<Color> senderNameColors;

  /// Behind a message the user jumped to, e.g. from message search, for a
  /// moment after it shows.
  final Color revealedMessageColor;

  /// Corner radius of the composer's text field.
  final double composerRadius;

  /// Corner radius of text fields, e.g. on the login screen.
  final double fieldRadius;

  /// Corner radius of buttons.
  final double buttonRadius;

  /// Corner radius of the top of bottom sheets.
  final double sheetRadius;

  /// The curve of what pops, slides or grows: bubbles, pills, sheets.
  final Curve springCurve;

  /// How long [springCurve] motion takes.
  final Duration springDuration;

  /// How long fades and color changes take.
  final Duration fadeDuration;

  /// The colour of the member [colorIndex] names, from [senderNameColors].
  Color senderNameColor(int colorIndex) =>
      senderNameColors[colorIndex % senderNameColors.length];

  @override
  TinodeChatTheme copyWith({
    Color? ownBubbleColor,
    Color? onOwnBubbleColor,
    Color? ownMetaColor,
    Color? peerBubbleColor,
    Color? onPeerBubbleColor,
    Color? peerMetaColor,
    double? bubbleRadius,
    bool? bubbleTail,
    double? photoRadius,
    double? sameRunGap,
    double? newRunGap,
    Color? wallpaperColor,
    Color? wallpaperDotColor,
    Color? dateChipColor,
    Color? glassColor,
    Color? glassEdgeColor,
    Color? linkColor,
    Color? unreadBadgeColor,
    Color? onUnreadBadgeColor,
    Color? mutedBadgeColor,
    Color? onlineColor,
    Color? missedCallColor,
    Color? readReceiptColor,
    Color? waveOffColor,
    List<Color>? senderNameColors,
    Color? revealedMessageColor,
    double? composerRadius,
    double? fieldRadius,
    double? buttonRadius,
    double? sheetRadius,
    Curve? springCurve,
    Duration? springDuration,
    Duration? fadeDuration,
  }) => TinodeChatTheme(
    ownBubbleColor: ownBubbleColor ?? this.ownBubbleColor,
    onOwnBubbleColor: onOwnBubbleColor ?? this.onOwnBubbleColor,
    ownMetaColor: ownMetaColor ?? this.ownMetaColor,
    peerBubbleColor: peerBubbleColor ?? this.peerBubbleColor,
    onPeerBubbleColor: onPeerBubbleColor ?? this.onPeerBubbleColor,
    peerMetaColor: peerMetaColor ?? this.peerMetaColor,
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    bubbleTail: bubbleTail ?? this.bubbleTail,
    photoRadius: photoRadius ?? this.photoRadius,
    sameRunGap: sameRunGap ?? this.sameRunGap,
    newRunGap: newRunGap ?? this.newRunGap,
    wallpaperColor: wallpaperColor ?? this.wallpaperColor,
    wallpaperDotColor: wallpaperDotColor ?? this.wallpaperDotColor,
    dateChipColor: dateChipColor ?? this.dateChipColor,
    glassColor: glassColor ?? this.glassColor,
    glassEdgeColor: glassEdgeColor ?? this.glassEdgeColor,
    linkColor: linkColor ?? this.linkColor,
    unreadBadgeColor: unreadBadgeColor ?? this.unreadBadgeColor,
    onUnreadBadgeColor: onUnreadBadgeColor ?? this.onUnreadBadgeColor,
    mutedBadgeColor: mutedBadgeColor ?? this.mutedBadgeColor,
    onlineColor: onlineColor ?? this.onlineColor,
    missedCallColor: missedCallColor ?? this.missedCallColor,
    readReceiptColor: readReceiptColor ?? this.readReceiptColor,
    waveOffColor: waveOffColor ?? this.waveOffColor,
    senderNameColors: senderNameColors ?? this.senderNameColors,
    revealedMessageColor: revealedMessageColor ?? this.revealedMessageColor,
    composerRadius: composerRadius ?? this.composerRadius,
    fieldRadius: fieldRadius ?? this.fieldRadius,
    buttonRadius: buttonRadius ?? this.buttonRadius,
    sheetRadius: sheetRadius ?? this.sheetRadius,
    springCurve: springCurve ?? this.springCurve,
    springDuration: springDuration ?? this.springDuration,
    fadeDuration: fadeDuration ?? this.fadeDuration,
  );

  @override
  TinodeChatTheme lerp(TinodeChatTheme? other, double t) {
    if (other == null) {
      return this;
    }
    Color color(Color a, Color b) => Color.lerp(a, b, t)!;
    double number(double a, double b) => lerpDouble(a, b, t)!;
    // What can't be blended switches halfway.
    final near = t < 0.5 ? this : other;
    return TinodeChatTheme(
      ownBubbleColor: color(ownBubbleColor, other.ownBubbleColor),
      onOwnBubbleColor: color(onOwnBubbleColor, other.onOwnBubbleColor),
      ownMetaColor: color(ownMetaColor, other.ownMetaColor),
      peerBubbleColor: color(peerBubbleColor, other.peerBubbleColor),
      onPeerBubbleColor: color(onPeerBubbleColor, other.onPeerBubbleColor),
      peerMetaColor: color(peerMetaColor, other.peerMetaColor),
      bubbleRadius: number(bubbleRadius, other.bubbleRadius),
      bubbleTail: near.bubbleTail,
      photoRadius: number(photoRadius, other.photoRadius),
      sameRunGap: number(sameRunGap, other.sameRunGap),
      newRunGap: number(newRunGap, other.newRunGap),
      wallpaperColor: color(wallpaperColor, other.wallpaperColor),
      wallpaperDotColor: color(wallpaperDotColor, other.wallpaperDotColor),
      dateChipColor: color(dateChipColor, other.dateChipColor),
      glassColor: color(glassColor, other.glassColor),
      glassEdgeColor: color(glassEdgeColor, other.glassEdgeColor),
      linkColor: color(linkColor, other.linkColor),
      unreadBadgeColor: color(unreadBadgeColor, other.unreadBadgeColor),
      onUnreadBadgeColor: color(onUnreadBadgeColor, other.onUnreadBadgeColor),
      mutedBadgeColor: color(mutedBadgeColor, other.mutedBadgeColor),
      onlineColor: color(onlineColor, other.onlineColor),
      missedCallColor: color(missedCallColor, other.missedCallColor),
      readReceiptColor: color(readReceiptColor, other.readReceiptColor),
      waveOffColor: color(waveOffColor, other.waveOffColor),
      senderNameColors: senderNameColors.length == other.senderNameColors.length
          ? [
              for (var i = 0; i < senderNameColors.length; i++)
                color(senderNameColors[i], other.senderNameColors[i]),
            ]
          : near.senderNameColors,
      revealedMessageColor: color(
        revealedMessageColor,
        other.revealedMessageColor,
      ),
      composerRadius: number(composerRadius, other.composerRadius),
      fieldRadius: number(fieldRadius, other.fieldRadius),
      buttonRadius: number(buttonRadius, other.buttonRadius),
      sheetRadius: number(sheetRadius, other.sheetRadius),
      springCurve: near.springCurve,
      springDuration: near.springDuration,
      fadeDuration: near.fadeDuration,
    );
  }
}
