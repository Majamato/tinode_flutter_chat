import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_player.dart';

/// [VoicePlayer] over `just_audio`. A recording in memory plays from a
/// temporary copy, deleted with the next one.
final class JustAudioVoicePlayer implements VoicePlayer {
  final _player = AudioPlayer();
  File? _copy;

  @override
  late final Stream<Duration> positions = _player.createPositionStream(
    minPeriod: const Duration(milliseconds: 50),
    maxPeriod: const Duration(milliseconds: 100),
  );

  @override
  Stream<void> get completions => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  Future<Duration?> openFile(String path) async {
    try {
      return await _player.setFilePath(path);
    } on Object catch (e) {
      throw VoicePlayerException(e);
    }
  }

  @override
  Future<Duration?> openBytes(Uint8List bytes, {String? mimeType}) async {
    try {
      await _deleteCopy();
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final copy = _copy = File('${directory.path}/voice-play-$stamp');
      await copy.writeAsBytes(bytes, flush: true);
      return await _player.setFilePath(copy.path);
    } on VoicePlayerException {
      rethrow;
    } on Object catch (e) {
      throw VoicePlayerException(e);
    }
  }

  @override
  void play() {
    // The future only completes once playback pauses or ends.
    unawaited(_player.play().catchError((Object _) {}));
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double rate) => _player.setSpeed(rate);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _deleteCopy();
  }

  Future<void> _deleteCopy() async {
    final copy = _copy;
    _copy = null;
    if (copy != null && copy.existsSync()) {
      await copy.delete();
    }
  }
}
