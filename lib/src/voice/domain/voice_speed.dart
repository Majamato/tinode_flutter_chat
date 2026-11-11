/// How fast voice messages play, the same for all of them.
enum VoiceSpeed {
  normal(1),
  fast(1.5),
  fastest(2);

  const VoiceSpeed(this.rate);

  /// Times normal speed.
  final double rate;

  /// The one a tap moves to, back to [normal] after [fastest].
  VoiceSpeed get next => values[(index + 1) % values.length];
}
