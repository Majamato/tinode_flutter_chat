import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The voice message playing, or paused part way, in the chat: the one
/// with [key]. [loading] while the player opens its file; it already
/// shows as [playing] then.
final class VoicePlayback with ValueObject {
  const VoicePlayback({
    required this.key,
    this.playing = false,
    this.loading = false,
    this.position = Duration.zero,
    this.duration,
  });

  /// Which message, see `VoiceSource.key`.
  final String key;
  final bool playing;
  final bool loading;
  final Duration position;

  /// How long it plays, once known.
  final Duration? duration;

  /// How far it got, 0..1; 0 while the duration is unknown.
  double get progress => switch (duration) {
    final d? when d > Duration.zero =>
      (position.inMicroseconds / d.inMicroseconds).clamp(0, 1).toDouble(),
    _ => 0,
  };

  VoicePlayback copyWith({
    bool? playing,
    bool? loading,
    Duration? position,
    Duration? duration,
  }) => VoicePlayback(
    key: key,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );

  @override
  List<Object?> get props => [key, playing, loading, position, duration];
}

/// Where a voice message's recording is, and its [key] for playback.
sealed class VoiceSource with ValueObject {
  const VoiceSource();

  /// Tells one message's playback from another's.
  String get key;
}

/// A received recording, uploaded to the server.
final class RefVoiceSource extends VoiceSource {
  const RefVoiceSource(this.ref);

  final String ref;

  @override
  String get key => 'ref:$ref';

  @override
  List<Object?> get props => [ref];
}

/// A recording sent inside the message.
final class InlineVoiceSource extends VoiceSource {
  const InlineVoiceSource({
    required this.id,
    required this.bytes,
    this.mimeType,
  });

  /// The message, e.g. its topic and seq.
  final String id;
  final Uint8List bytes;
  final String? mimeType;

  @override
  String get key => 'inline:$id';

  @override
  List<Object?> get props => [id, bytes, mimeType];
}

/// One of the user's recordings still in the outbox, from its staged copy.
final class StagedVoiceSource extends VoiceSource {
  const StagedVoiceSource(this.stagedId, {this.mimeType});

  final String stagedId;
  final String? mimeType;

  @override
  String get key => 'staged:$stagedId';

  @override
  List<Object?> get props => [stagedId, mimeType];
}
