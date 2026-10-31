import 'dart:async';
import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder.dart';

/// A [VoiceRecorder] without a microphone: levels come from [level], and
/// a stopped recording is [bytes].
final class FakeVoiceRecorder implements VoiceRecorder {
  /// What [hasPermission] answers.
  bool permission = true;

  /// Makes [start] throw.
  bool failStart = false;

  /// Makes [pause] and [resume] throw.
  bool failPause = false;

  /// The recording [stop] returns.
  Uint8List bytes = Uint8List.fromList(List.generate(512, (i) => i % 256));

  final _levels = StreamController<double>.broadcast();

  bool recording = false;
  bool paused = false;
  int starts = 0;
  int pauses = 0;
  int resumes = 0;
  int cancels = 0;
  bool disposed = false;
  final deleted = <PickedFile>[];

  /// Reports [dbfs] as the level now.
  void level(double dbfs) => _levels.add(dbfs);

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start() async {
    if (failStart) {
      throw const VoiceRecorderException('no microphone');
    }
    recording = true;
    paused = false;
    starts++;
  }

  @override
  Future<void> pause() async {
    if (failPause) {
      throw const VoiceRecorderException('cannot pause');
    }
    paused = true;
    pauses++;
  }

  @override
  Future<void> resume() async {
    if (failPause) {
      throw const VoiceRecorderException('cannot resume');
    }
    paused = false;
    resumes++;
  }

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<PickedFile?> stop() async {
    recording = false;
    paused = false;
    final recorded = bytes;
    return PickedFile(
      name: 'voice-$starts.m4a',
      length: recorded.length,
      openRead: () => Stream.value(recorded),
      mimeType: 'audio/mp4',
      path: '/tmp/voice-$starts.m4a',
    );
  }

  @override
  Future<void> cancel() async {
    recording = false;
    paused = false;
    cancels++;
  }

  @override
  Future<void> delete(PickedFile recording) async => deleted.add(recording);

  @override
  Future<void> dispose() async {
    disposed = true;
    await _levels.close();
  }
}
