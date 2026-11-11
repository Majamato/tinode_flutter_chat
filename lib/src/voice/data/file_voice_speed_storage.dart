import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed_storage.dart';

/// A JSON file in the app's support directory, next to the chat caches.
final class FileVoiceSpeedStorage implements VoiceSpeedStorage {
  FileVoiceSpeedStorage({this._directory = getApplicationSupportDirectory});

  static const _fileName = 'tinode_voice_speed.json';

  final Future<Directory> Function() _directory;
  Future<void> _writes = Future.value();

  Future<File> get _file async =>
      File('${(await _directory()).path}/$_fileName');

  @override
  Future<VoiceSpeed> read() async {
    try {
      final file = await _file;
      if (!file.existsSync()) {
        return VoiceSpeed.normal;
      }
      return switch (jsonDecode(await file.readAsString())) {
        {'speed': final String name} =>
          VoiceSpeed.values.asNameMap()[name] ?? VoiceSpeed.normal,
        _ => VoiceSpeed.normal,
      };
    } on Object catch (e, stackTrace) {
      _log('Could not read the voice speed', e, stackTrace);
      return VoiceSpeed.normal;
    }
  }

  @override
  Future<void> write(VoiceSpeed speed) => _writes = _writes.then((_) async {
    try {
      final file = await _file;
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'speed': speed.name}));
    } on Object catch (e, stackTrace) {
      _log('Could not save the voice speed', e, stackTrace);
    }
  });

  static void _log(String message, Object error, StackTrace stackTrace) => log(
    message,
    name: 'tinode_flutter_chat',
    error: error,
    stackTrace: stackTrace,
  );
}
