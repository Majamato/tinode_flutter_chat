import 'package:flutter/material.dart';

/// The colors of the chat that don't come from the palette, for light and
/// dark mode; see `docs/design.md`.
final class ChatNeutrals {
  const ChatNeutrals._({
    required this.page,
    required this.background,
    required this.surface,
    required this.card,
    required this.peerBubble,
    required this.text,
    required this.muted,
    required this.line,
    required this.glass,
    required this.glassEdge,
    required this.glassShadow,
    required this.waveOff,
    required this.dateChip,
    required this.mutedBadge,
  });

  /// The neutrals for [brightness].
  factory ChatNeutrals.of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static const light = ChatNeutrals._(
    page: Color(0xFFF4F3F0),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F3F0),
    card: Color(0xFFFFFFFF),
    peerBubble: Color(0xFFFFFFFF),
    text: Color(0xFF14161B),
    muted: Color(0xFF6B7079),
    line: Color(0xFFE7E5E0),
    glass: Color(0xD1FFFFFF),
    // Strong enough that white glass, the tab bar above all, still shows
    // its edge on the white lists.
    glassEdge: Color(0x1F14161B),
    glassShadow: Color(0x3314161B),
    waveOff: Color(0xFFC9CCD2),
    dateChip: Color(0x5714161B),
    mutedBadge: Color(0xFF9BA1AB),
  );

  static const dark = ChatNeutrals._(
    page: Color(0xFF07080B),
    background: Color(0xFF121419),
    surface: Color(0xFF1E2129),
    card: Color(0xFF1A1D24),
    peerBubble: Color(0xFF262A33),
    text: Color(0xFFF7F5F2),
    muted: Color(0xFFB0B6C0),
    line: Color(0x1FFFFFFF),
    glass: Color(0xDB121419),
    glassEdge: Color(0x24FFFFFF),
    glassShadow: Color(0x66000000),
    waveOff: Color(0xFF5A606B),
    dateChip: Color(0x2EFFFFFF),
    mutedBadge: Color(0xFF5A606B),
  );

  /// End call, the recording dot, missed calls.
  static const danger = Color(0xFFD93036);

  /// The presence dot, and accepting a call.
  static const online = Color(0xFF22B573);

  // The call screens are always dark, whatever the brightness.

  /// Over the call screen's moving background.
  static const callScrim = Color(0x2E000000);

  /// The top of a video call, behind the name and the timer.
  static const callShade = Color(0x8C000000);

  /// The glass of a call control.
  static const callControl = Color(0x29FFFFFF);

  /// A call control that is switched on, e.g. the loudspeaker.
  static const callControlActive = Color(0xF2FFFFFF);

  /// The ring around the caller's avatar and the self-view's border.
  static const callOutline = Color(0x40FFFFFF);

  /// The video call's floating control pill.
  static const callPill = Color(0x7314161B);
  static const callPillEdge = Color(0x1FFFFFFF);

  /// The outermost background, and the chat wallpaper in dark mode.
  final Color page;

  /// Lists and sheets.
  final Color background;

  /// Inputs, chips and cards on [background].
  final Color surface;

  /// Settings groups.
  final Color card;
  final Color peerBubble;
  final Color text;

  /// Times, previews and labels.
  final Color muted;

  /// Dividers and borders.
  final Color line;

  /// Floating glass: its fill and edge.
  final Color glass;
  final Color glassEdge;

  /// The soft shadow under floating glass.
  final Color glassShadow;

  /// The unplayed part of a waveform.
  final Color waveOff;
  final Color dateChip;

  /// The unread badge of a muted chat.
  final Color mutedBadge;
}
