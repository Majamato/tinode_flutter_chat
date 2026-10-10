/// Thins out progress reports, so a transfer rebuilds its widget a few
/// times a second rather than once per chunk: it lets a report through
/// once [interval] has passed and the transfer moved by [step] of its total
/// since the last one. The first and the final report always pass.
final class ProgressThrottle {
  ProgressThrottle({
    this.interval = const Duration(milliseconds: 100),
    this.step = 0.01,
  });

  final Duration interval;
  final double step;
  DateTime? _lastAt;
  int _lastSent = 0;

  /// Whether to pass on the report of [sent] bytes of [total] at [now].
  bool admit(int sent, int? total, DateTime now) {
    final lastAt = _lastAt;
    final done = total != null && sent >= total;
    final moved = total == null || total <= 0
        ? sent > _lastSent
        : (sent - _lastSent) / total >= step;
    if (lastAt == null ||
        done ||
        (moved && now.difference(lastAt) >= interval)) {
      _lastAt = now;
      _lastSent = sent;
      return true;
    }
    return false;
  }
}
