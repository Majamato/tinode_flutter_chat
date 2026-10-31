import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tinode_flutter_chat/src/appearance/domain/stored_appearance.dart';

/// Keeps the look the user picked on this device, for every user of it.
abstract interface class AppearanceStorage {
  /// What was saved last, or the defaults.
  Future<StoredAppearance> read();

  /// Saves [appearance]; writes land in the order they were made.
  Future<void> write(StoredAppearance appearance);
}

/// A JSON file in the app's support directory, next to the chat caches.
final class FileAppearanceStorage implements AppearanceStorage {
  FileAppearanceStorage({
    Future<Directory> Function() directory = getApplicationSupportDirectory,
  }) : _directory = directory;

  static const _fileName = 'tinode_appearance.json';

  final Future<Directory> Function() _directory;
  Future<void> _writes = Future.value();

  Future<File> get _file async =>
      File('${(await _directory()).path}/$_fileName');

  @override
  Future<StoredAppearance> read() async {
    try {
      final file = await _file;
      if (!file.existsSync()) {
        return const StoredAppearance();
      }
      return switch (jsonDecode(await file.readAsString())) {
        final Map<String, Object?> json => StoredAppearance.fromJson(json),
        _ => const StoredAppearance(),
      };
    } on Object catch (e, stackTrace) {
      _log('Could not read the appearance', e, stackTrace);
      return const StoredAppearance();
    }
  }

  @override
  Future<void> write(StoredAppearance appearance) =>
      _writes = _writes.then((_) async {
        try {
          final file = await _file;
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(appearance.toJson()));
        } on Object catch (e, stackTrace) {
          _log('Could not save the appearance', e, stackTrace);
        }
      });

  static void _log(String message, Object error, StackTrace stackTrace) => log(
    message,
    name: 'tinode_flutter_chat',
    error: error,
    stackTrace: stackTrace,
  );
}
