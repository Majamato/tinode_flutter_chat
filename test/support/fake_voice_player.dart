import 'dart:async';
import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/voice/domain/voice_player.dart';

/// A [VoicePlayer] without speakers: it records what it was told, and a
/// test drives it with [moveTo] and [finish].
final class FakeVoicePlayer implements VoicePlayer {
  /// What opening a recording says its duration is.
  Duration? duration = const Duration(seconds: 3);

  /// Makes opening fail, as a format the device can't play would.
  bool failOpen = false;

  /// When set, opening waits for it, as a real player preparing would.
  Completer<void>? openGate;

  /// When set, seeking waits for it.
  Completer<void>? seekGate;

  final _positions = StreamController<Duration>.broadcast();
  final _completions = StreamController<void>.broadcast();

  /// The paths opened, and `bytes:<length>` for recordings in memory.
  final opened = <String>[];
  bool playing = false;
  int stops = 0;
  Duration? seekedTo;

  /// Every seek, in the order sent.
  final seeks = <Duration>[];
  bool disposed = false;

  /// Reports playback at [position].
  void moveTo(Duration position) => _positions.add(position);

  /// Reports the end of the recording.
  void finish() => _completions.add(null);

  @override
  Future<Duration?> openFile(String path) async {
    await openGate?.future;
    if (failOpen) {
      throw const VoicePlayerException('cannot open');
    }
    opened.add(path);
    return duration;
  }

  @override
  Future<Duration?> openBytes(Uint8List bytes, {String? mimeType}) async {
    await openGate?.future;
    if (failOpen) {
      throw const VoicePlayerException('cannot open');
    }
    opened.add('bytes:${bytes.length}');
    return duration;
  }

  @override
  void play() => playing = true;

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> seek(Duration position) async {
    seekedTo = position;
    seeks.add(position);
    await seekGate?.future;
  }

  @override
  Future<void> stop() async {
    playing = false;
    stops++;
  }

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Stream<void> get completions => _completions.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _positions.close();
    await _completions.close();
  }
}
