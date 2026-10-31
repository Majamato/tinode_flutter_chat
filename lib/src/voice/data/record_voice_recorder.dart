import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_waveform.dart';

/// [VoiceRecorder] over `record`: AAC in MPEG-4 (`.m4a`), mono, 16 kHz at
/// 24 kbps, as Tindroid records, in the temporary directory.
final class RecordVoiceRecorder implements VoiceRecorder {
  static const mimeType = 'audio/mp4';

  static const _config = RecordConfig(
    bitRate: 24000,
    sampleRate: 16000,
    numChannels: 1,
  );

  final _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    try {
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      await _recorder.start(
        _config,
        path: '${directory.path}/voice-$stamp.m4a',
      );
    } on Object catch (e) {
      throw VoiceRecorderException(e);
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _recorder.pause();
    } on Object catch (e) {
      throw VoiceRecorderException(e);
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _recorder.resume();
    } on Object catch (e) {
      throw VoiceRecorderException(e);
    }
  }

  @override
  Stream<double> get levels => _recorder
      .onAmplitudeChanged(voiceSampleInterval)
      .map((amplitude) => amplitude.current);

  @override
  Future<PickedFile?> stop() async {
    final String? path;
    try {
      path = await _recorder.stop();
    } on Object catch (e) {
      throw VoiceRecorderException(e);
    }
    if (path == null) {
      return null;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return PickedFile(
      name: file.uri.pathSegments.last,
      length: await file.length(),
      openRead: file.openRead,
      mimeType: mimeType,
      path: path,
    );
  }

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> delete(PickedFile recording) async {
    if (recording.path case final path?) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
