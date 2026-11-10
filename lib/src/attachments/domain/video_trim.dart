import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The part of a video to send, from [start] to [end].
final class VideoTrim with ValueObject {
  const VideoTrim(this.start, this.end);

  /// The first [maxLength] of a video of [total].
  factory VideoTrim.initial(Duration total, Duration maxLength) =>
      VideoTrim(Duration.zero, _earlier(total, maxLength));

  /// The shortest part that can be chosen.
  static const minLength = Duration(seconds: 1);

  final Duration start;
  final Duration end;

  Duration get length => end - start;

  /// Whether this is all of a video of [total].
  bool coversAll(Duration total) => start <= Duration.zero && end >= total;

  /// With its start moved towards [value], as far as a video of [total]
  /// and [maxLength] allow.
  VideoTrim withStart(
    Duration value, {
    required Duration total,
    required Duration maxLength,
  }) {
    final longest = _later(end - maxLength, Duration.zero);
    final shortest = _later(end - _shortest(total), Duration.zero);
    return VideoTrim(_clamp(value, longest, shortest), end);
  }

  /// With its end moved towards [value], as far as a video of [total] and
  /// [maxLength] allow.
  VideoTrim withEnd(
    Duration value, {
    required Duration total,
    required Duration maxLength,
  }) {
    final shortest = _earlier(start + _shortest(total), total);
    final longest = _earlier(start + maxLength, total);
    return VideoTrim(start, _clamp(value, shortest, longest));
  }

  /// The same length, starting as near [value] as a video of [total]
  /// allows.
  VideoTrim movedTo(Duration value, {required Duration total}) {
    final moved = _clamp(value, Duration.zero, total - length);
    return VideoTrim(moved, moved + length);
  }

  /// [minLength], or the whole of a video shorter than that.
  static Duration _shortest(Duration total) => _earlier(minLength, total);

  static Duration _earlier(Duration a, Duration b) => a < b ? a : b;

  static Duration _later(Duration a, Duration b) => a > b ? a : b;

  static Duration _clamp(Duration value, Duration low, Duration high) =>
      _later(low, _earlier(value, high));

  @override
  List<Object?> get props => [start, end];
}
