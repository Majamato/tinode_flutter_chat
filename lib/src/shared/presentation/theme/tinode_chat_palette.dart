import 'package:flutter/painting.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The brand colors the chat is drawn from: one strong color for the
/// user's own messages and the primary actions, and the few that go with
/// it. Everything else stays neutral.
///
/// Pass one to `TinodeChatTheme.materialTheme` (or
/// `TinodeChatTheme.fromPalette`) to brand the chat:
///
/// ```dart
/// const plum = TinodeChatPalette(
///   primary: Color(0xFF5B1A8C),
///   night: Color(0xFF6E29A8),
///   bright: Color(0xFF8A3FD1),
///   accent: Color(0xFFFF9A3D),
///   soft: Color(0xFFF1E5FA),
///   ink: Color(0xFF42106A),
///   onDark: Color(0xFFC08BFF),
///   deep: Color(0xFF1A0730),
///   scene: Color(0xFF28133D),
/// );
///
/// MaterialApp(
///   theme: TinodeChatTheme.materialTheme(palette: plum),
///   darkTheme: TinodeChatTheme.materialTheme(
///     palette: plum,
///     brightness: Brightness.dark,
///   ),
/// )
/// ```
final class TinodeChatPalette with ValueObject {
  /// Creates a palette with every role given.
  const TinodeChatPalette({
    required this.primary,
    required this.night,
    required this.bright,
    required this.accent,
    required this.soft,
    required this.ink,
    required this.onDark,
    required this.deep,
    required this.scene,
  });

  /// The palette the chat uses when the app gives none: a slate blue.
  static const neutral = TinodeChatPalette(
    primary: Color(0xFF34507A),
    night: Color(0xFF3F5F8F),
    bright: Color(0xFF6B8CC4),
    accent: Color(0xFFF2A541),
    soft: Color(0xFFE8EDF5),
    ink: Color(0xFF23385A),
    onDark: Color(0xFF9DB8E8),
    deep: Color(0xFF0B1424),
    scene: Color(0xFF172236),
  );

  /// The user's own messages, primary buttons, selected chips and unread
  /// badges in light mode. White text on it must pass 4.5:1.
  final Color primary;

  /// Takes the place of [primary] in dark mode, a little lifted so it
  /// stands out from near-black. White text on it must pass 4.5:1.
  final Color night;

  /// Decoration only, never behind text: waveform highlights, photo
  /// placeholders, the blobs behind a call, recording rings.
  final Color bright;

  /// The clashing pop for small decorations, never behind small text.
  final Color accent;

  /// A light tint of [primary]: the chat wallpaper in light mode and
  /// secondary buttons.
  final Color soft;

  /// Text and links in the brand's hue on light backgrounds: links, the
  /// back button, read ticks outside a bubble.
  final Color ink;

  /// Takes the place of [ink] in dark mode.
  final Color onDark;

  /// The base color behind a voice call.
  final Color deep;

  /// The base color in place of the remote video before it shows.
  final Color scene;

  @override
  List<Object?> get props => [
    primary,
    night,
    bright,
    accent,
    soft,
    ink,
    onDark,
    deep,
    scene,
  ];
}
