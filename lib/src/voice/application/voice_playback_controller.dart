import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_inputs.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_failure.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_player.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_seek_gate.dart';

part 'voice_playback_controller.g.dart';

/// The voice message playing, one at a time; null when none is. Starting
/// another stops the first; a call or a recording stops it too, and one
/// that plays to its end rewinds. Each bubble selects its own key, so only
/// the playing one rebuilds.
@Riverpod(keepAlive: true)
class VoicePlaybackController extends _$VoicePlaybackController {
  VoicePlayer? _player;

  /// Between the player and the position shown: one seek at a time, and no
  /// stale or early positions.
  late final _gate = VoiceSeekGate((to) => _opened.seek(to));
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  VoicePlayback? build() {
    ref
      ..listen(
        callControllerProvider.select((call) => call != null && !call.isOver),
        (_, inCall) {
          if (inCall) {
            unawaited(stop());
          }
        },
      )
      ..onDispose(() {
        for (final s in _subscriptions) {
          unawaited(s.cancel());
        }
        unawaited(_player?.dispose());
      });
    return null;
  }

  VoicePlayer get _opened {
    if (_player case final player?) {
      return player;
    }
    final player = _player = ref.read(voicePlayerFactoryProvider)();
    _subscriptions.addAll([
      player.positions.listen((position) {
        if (state case final playback?
            when playback.playing && _gate.accepts(position, playing: true)) {
          state = playback.copyWith(position: position);
        }
      }),
      player.completions.listen((_) => unawaited(stop())),
    ]);
    return player;
  }

  /// Plays the message [source] holds from its [file] on this device (see
  /// `voiceFileProvider`), or pauses it, or resumes it where it paused. It
  /// shows as playing at once, while the player opens the file. [duration]
  /// is what the message says, until the file tells. Returns
  /// [VoiceFailure.cannotPlay] when the file could not be played.
  Future<VoiceFailure?> toggle(
    VoiceSource source,
    LocalFile file, {
    Duration? duration,
  }) async {
    final player = _opened;
    final current = state;
    if (current != null && current.key == source.key) {
      if (current.loading) {
        return null;
      }
      if (current.playing) {
        state = current.copyWith(playing: false);
        await player.pause();
      } else {
        state = current.copyWith(playing: true);
        player.play();
      }
      return null;
    }

    if (current != null) {
      await player.stop();
    }
    _gate.restart();
    state = VoicePlayback(
      key: source.key,
      playing: true,
      loading: true,
      duration: duration,
    );
    try {
      final opened = await _open(player, source, file);
      if (state?.key != source.key) {
        return null; // Another message was picked meanwhile.
      }
      state = VoicePlayback(
        key: source.key,
        playing: true,
        duration: opened ?? duration,
      );
      player.play();
      return null;
    } on Object {
      if (state?.key == source.key) {
        state = null;
      }
      return VoiceFailure.cannotPlay;
    }
  }

  /// Moves the playing message [key] to [fraction] (0..1) of its length,
  /// which shows at once. Quick seeks end at the last.
  Future<void> seek(String key, double fraction) async {
    final current = state;
    final duration = current?.duration;
    if (current == null || current.key != key || duration == null) {
      return;
    }
    final position = duration * fraction.clamp(0, 1);
    state = current.copyWith(position: position);
    _gate.seek(position);
  }

  /// Stops whatever plays.
  Future<void> stop() async {
    if (state == null) {
      return;
    }
    state = null;
    await _player?.stop();
  }

  Future<Duration?> _open(
    VoicePlayer player,
    VoiceSource source,
    LocalFile file,
  ) {
    final mimeType = switch (source) {
      InlineVoiceSource(:final mimeType) => mimeType,
      StagedVoiceSource(:final mimeType) => mimeType,
      RefVoiceSource() => null,
    };
    return switch (file) {
      LocalFile(:final path?) => player.openFile(path),
      LocalFile(:final bytes?) => player.openBytes(bytes, mimeType: mimeType),
      _ => throw const VoicePlayerException('No file'),
    };
  }
}
