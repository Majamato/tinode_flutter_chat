/// The sizes icons are drawn at: use one of these rather than a number, so
/// that icons in the same place match.
abstract final class ChatIconSize {
  /// Read ticks and chips on media.
  static const double tiny = 14;

  /// Indicators in a line of text: a muted chat, a message preview.
  static const double small = 16;

  /// Beside a label or a field's hint.
  static const double label = 18;

  /// Everything else: app bars, the composer, tabs, tiles and rows.
  static const double standard = 24;

  /// Alone in a large round control: calls, play, retry.
  static const double large = 28;

  /// File icons in a bubble.
  static const double xlarge = 32;

  /// The one thing on a screen, such as a file about to be sent.
  static const double hero = 64;
}
