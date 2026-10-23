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
    glassEdge: Color(0x0F14161B),
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
    waveOff: Color(0xFF5A606B),
    dateChip: Color(0x2EFFFFFF),
    mutedBadge: Color(0xFF5A606B),
  );

  /// End call, the recording dot, missed calls.
  static const danger = Color(0xFFD93036);

  /// The presence dot.
  static const online = Color(0xFF22B573);

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

  /// Frosted bars.
  final Color glass;
  final Color glassEdge;

  /// The unplayed part of a waveform.
  final Color waveOff;
  final Color dateChip;

  /// The unread badge of a muted chat.
  final Color mutedBadge;
}
