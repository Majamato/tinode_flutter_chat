/// Sits between a player and the position shown, so the playhead never
/// jumps:
///
/// 1. Seeks run one at a time: a new target while one runs waits, replacing
///    any older waiting one, so quick taps end at the last.
/// 2. While a seek runs, the positions the player reports are refused:
///    they are from before it.
/// 3. While playing, a position behind the one shown is refused: playback
///    only moves forward, so it is stale, or early as the player starts.
///    The first position after a seek or a [restart] may go anywhere.
final class VoiceSeekGate {
  VoiceSeekGate(this._seek);

  /// Moves the player, completing once it is there.
  final Future<void> Function(Duration to) _seek;

  /// The newest target waiting for the running seek to end.
  Duration? _next;
  bool _seeking = false;

  /// The position shown now.
  Duration _shown = Duration.zero;

  /// Whether the next position may go anywhere.
  bool _free = true;

  /// Whether a seek is running.
  bool get seeking => _seeking;

  /// Moves the player to [to], which shows at once (rule 1).
  void seek(Duration to) {
    _shown = to;
    _free = true;
    if (_seeking) {
      _next = to;
      return;
    }
    _run(to).ignore();
  }

  /// Lets the next position go anywhere, as when a recording starts over,
  /// and drops a waiting target, which was for the one before.
  void restart() {
    _next = null;
    _shown = Duration.zero;
    _free = true;
  }

  /// Whether [position], which the player reported, may show (rules 2
  /// and 3).
  bool accepts(Duration position, {required bool playing}) {
    if (_seeking) {
      return false;
    }
    if (playing && !_free && position < _shown) {
      return false;
    }
    _free = false;
    _shown = position;
    return true;
  }

  /// Sends [to] to the player, then the newest target that came meanwhile.
  Future<void> _run(Duration to) async {
    _seeking = true;
    Duration? target = to;
    while (target != null) {
      try {
        await _seek(target);
      } on Object {
        // A failed seek leaves the player where it was; its next report
        // shows as it is.
      }
      target = _next;
      _next = null;
    }
    _seeking = false;
    _free = true;
  }
}
