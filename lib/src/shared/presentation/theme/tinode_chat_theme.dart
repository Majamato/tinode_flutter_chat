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
    required this.callBackgroundColor,
    required this.onCallColor,
    required this.callBlobColors,
    required this.videoPlaceholderColor,
    required this.videoBlobColors,
    required this.callScrimColor,
    required this.callShadeColor,
    required this.callControlColor,
    required this.callControlActiveColor,
    required this.onCallControlActiveColor,
    required this.callOutlineColor,
    required this.callPillColor,
    required this.callPillEdgeColor,
    required this.acceptCallColor,
    required this.pageColor,
    required this.cardColor,
    required this.tabBarLensColor,
    required this.recordingColor,
    required this.composerRadius,
    required this.fieldRadius,
    required this.buttonRadius,
    required this.sheetRadius,
    required this.cardRadius,
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
      callBackgroundColor: Color.lerp(colors.primary, Colors.black, 0.75)!,
      onCallColor: Colors.white,
      callBlobColors: [
        colors.primary,
        colors.secondary.withValues(alpha: 0.7),
        colors.tertiary.withValues(alpha: 0.45),
      ],
      videoPlaceholderColor: Color.lerp(colors.primary, Colors.black, 0.85)!,
      videoBlobColors: [
        colors.tertiary.withValues(alpha: 0.35),
        colors.secondary.withValues(alpha: 0.35),
      ],
      callScrimColor: ChatNeutrals.callScrim,
      callShadeColor: ChatNeutrals.callShade,
      callControlColor: ChatNeutrals.callControl,
      callControlActiveColor: ChatNeutrals.callControlActive,
      onCallControlActiveColor: ChatNeutrals.light.text,
      callOutlineColor: ChatNeutrals.callOutline,
      callPillColor: ChatNeutrals.callPill,
      callPillEdgeColor: ChatNeutrals.callPillEdge,
      acceptCallColor: ChatNeutrals.online,
      pageColor: colors.surface,
      cardColor: colors.surfaceContainerHighest,
      tabBarLensColor: colors.primary.withValues(alpha: 0.12),
      recordingColor: colors.error,
      composerRadius: 22,
      fieldRadius: 4,
      buttonRadius: 20,
      sheetRadius: 28,
      cardRadius: 12,
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
      callBackgroundColor: palette.deep,
      onCallColor: onPrimary,
      callBlobColors: [
        palette.primary,
        palette.bright.withValues(alpha: 0.7),
        palette.accent.withValues(alpha: 0.45),
      ],
      videoPlaceholderColor: palette.scene,
      videoBlobColors: [
        palette.accent.withValues(alpha: 0.35),
        palette.bright.withValues(alpha: 0.35),
      ],
      callScrimColor: ChatNeutrals.callScrim,
      callShadeColor: ChatNeutrals.callShade,
      callControlColor: ChatNeutrals.callControl,
      callControlActiveColor: ChatNeutrals.callControlActive,
      onCallControlActiveColor: ChatNeutrals.light.text,
      callOutlineColor: ChatNeutrals.callOutline,
      callPillColor: ChatNeutrals.callPill,
      callPillEdgeColor: ChatNeutrals.callPillEdge,
      acceptCallColor: ChatNeutrals.online,
      pageColor: neutrals.page,
      cardColor: neutrals.card,
      tabBarLensColor: dark
          ? const Color(0x24FFFFFF)
          : palette.primary.withValues(alpha: 0.1),
      recordingColor: ChatNeutrals.danger,
      composerRadius: 22,
      fieldRadius: 14,
      buttonRadius: 16,
      sheetRadius: 28,
      cardRadius: 20,
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

  /// Frosted bars (the composer, the tab bar), and the headers laid over
  /// the surface.
  final Color glassColor;

  /// The hairline between a bar and the content.
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

  /// Behind the voice call and the ringing screen, which are always dark.
  final Color callBackgroundColor;

  /// Text, icons and the pulsing rings on the call screens.
  final Color onCallColor;

  /// The blurred shapes drifting over [callBackgroundColor].
  final List<Color> callBlobColors;

  /// Where the peer's video shows, until it arrives.
  final Color videoPlaceholderColor;

  /// The soft shapes on [videoPlaceholderColor].
  final List<Color> videoBlobColors;

  /// Over the call background, under the content.
  final Color callScrimColor;

  /// The top of a video call, fading down behind the name and the timer.
  final Color callShadeColor;

  /// The glass of a call control, and of the reconnecting pill.
  final Color callControlColor;

  /// A call control that is switched on, e.g. the loudspeaker or mute.
  final Color callControlActiveColor;

  /// The icon on [callControlActiveColor].
  final Color onCallControlActiveColor;

  /// The ring around the peer's avatar and the edge of the self-view.
  final Color callOutlineColor;

  /// The video call's floating control pill.
  final Color callPillColor;

  /// The edge of [callPillColor].
  final Color callPillEdgeColor;

  /// The button that accepts a ringing call.
  final Color acceptCallColor;

  /// Behind settings screens, around their [cardColor] groups.
  final Color pageColor;

  /// Settings groups and cards on [pageColor].
  final Color cardColor;

  /// The lens that slides under the tab bar's current tab.
  final Color tabBarLensColor;

  /// The blinking dot while a voice message records, and the recording
  /// panel's delete button.
  final Color recordingColor;

  /// Corner radius of the composer's text field.
  final double composerRadius;

  /// Corner radius of text fields, e.g. on the login screen.
  final double fieldRadius;

  /// Corner radius of buttons.
  final double buttonRadius;

  /// Corner radius of the top of bottom sheets.
  final double sheetRadius;

  /// Corner radius of settings groups and cards.
  final double cardRadius;

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
    Color? callBackgroundColor,
    Color? onCallColor,
    List<Color>? callBlobColors,
    Color? videoPlaceholderColor,
    List<Color>? videoBlobColors,
    Color? callScrimColor,
    Color? callShadeColor,
    Color? callControlColor,
    Color? callControlActiveColor,
    Color? onCallControlActiveColor,
    Color? callOutlineColor,
    Color? callPillColor,
    Color? callPillEdgeColor,
    Color? acceptCallColor,
    Color? pageColor,
    Color? cardColor,
    Color? tabBarLensColor,
    Color? recordingColor,
    double? composerRadius,
    double? fieldRadius,
    double? buttonRadius,
    double? sheetRadius,
    double? cardRadius,
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
    callBackgroundColor: callBackgroundColor ?? this.callBackgroundColor,
    onCallColor: onCallColor ?? this.onCallColor,
    callBlobColors: callBlobColors ?? this.callBlobColors,
    videoPlaceholderColor: videoPlaceholderColor ?? this.videoPlaceholderColor,
    videoBlobColors: videoBlobColors ?? this.videoBlobColors,
    callScrimColor: callScrimColor ?? this.callScrimColor,
    callShadeColor: callShadeColor ?? this.callShadeColor,
    callControlColor: callControlColor ?? this.callControlColor,
    callControlActiveColor:
        callControlActiveColor ?? this.callControlActiveColor,
    onCallControlActiveColor:
        onCallControlActiveColor ?? this.onCallControlActiveColor,
    callOutlineColor: callOutlineColor ?? this.callOutlineColor,
    callPillColor: callPillColor ?? this.callPillColor,
    callPillEdgeColor: callPillEdgeColor ?? this.callPillEdgeColor,
    acceptCallColor: acceptCallColor ?? this.acceptCallColor,
    pageColor: pageColor ?? this.pageColor,
    cardColor: cardColor ?? this.cardColor,
    tabBarLensColor: tabBarLensColor ?? this.tabBarLensColor,
    recordingColor: recordingColor ?? this.recordingColor,
    composerRadius: composerRadius ?? this.composerRadius,
    fieldRadius: fieldRadius ?? this.fieldRadius,
    buttonRadius: buttonRadius ?? this.buttonRadius,
    sheetRadius: sheetRadius ?? this.sheetRadius,
    cardRadius: cardRadius ?? this.cardRadius,
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
    List<Color> colorList(List<Color> a, List<Color> b) => a.length == b.length
        ? [for (var i = 0; i < a.length; i++) color(a[i], b[i])]
        : (t < 0.5 ? a : b);
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
      senderNameColors: colorList(senderNameColors, other.senderNameColors),
      revealedMessageColor: color(
        revealedMessageColor,
        other.revealedMessageColor,
      ),
      callBackgroundColor: color(
        callBackgroundColor,
        other.callBackgroundColor,
      ),
      onCallColor: color(onCallColor, other.onCallColor),
      callBlobColors: colorList(callBlobColors, other.callBlobColors),
      videoPlaceholderColor: color(
        videoPlaceholderColor,
        other.videoPlaceholderColor,
      ),
      videoBlobColors: colorList(videoBlobColors, other.videoBlobColors),
      callScrimColor: color(callScrimColor, other.callScrimColor),
      callShadeColor: color(callShadeColor, other.callShadeColor),
      callControlColor: color(callControlColor, other.callControlColor),
      callControlActiveColor: color(
        callControlActiveColor,
        other.callControlActiveColor,
      ),
      onCallControlActiveColor: color(
        onCallControlActiveColor,
        other.onCallControlActiveColor,
      ),
      callOutlineColor: color(callOutlineColor, other.callOutlineColor),
      callPillColor: color(callPillColor, other.callPillColor),
      callPillEdgeColor: color(callPillEdgeColor, other.callPillEdgeColor),
      acceptCallColor: color(acceptCallColor, other.acceptCallColor),
      pageColor: color(pageColor, other.pageColor),
      cardColor: color(cardColor, other.cardColor),
      tabBarLensColor: color(tabBarLensColor, other.tabBarLensColor),
      recordingColor: color(recordingColor, other.recordingColor),
      composerRadius: number(composerRadius, other.composerRadius),
      fieldRadius: number(fieldRadius, other.fieldRadius),
      buttonRadius: number(buttonRadius, other.buttonRadius),
      sheetRadius: number(sheetRadius, other.sheetRadius),
      cardRadius: number(cardRadius, other.cardRadius),
      springCurve: near.springCurve,
      springDuration: near.springDuration,
      fadeDuration: near.fadeDuration,
    );
  }
}
