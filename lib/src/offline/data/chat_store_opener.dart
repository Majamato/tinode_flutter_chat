import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';

/// Opens and wipes the per-user caches, and remembers who last logged in
/// to each server, so the app can open that user's cache offline.
abstract interface class ChatStoreOpener {
  Future<ChatStore> open(Uri server, String userId);

  /// Deletes [userId]'s cache on [server]. Close the store first.
  Future<void> delete(Uri server, String userId);

  /// The user who last logged in to [server] on this device.
  Future<String?> lastUser(Uri server);

  Future<void> rememberUser(Uri server, String userId);

  Future<void> forgetUser(Uri server);
}

/// Opens [userId]'s cache, or, when that fails, an empty one in memory so
/// the chat still works online.
Future<ChatStore> openOrFallBack(
  ChatStoreOpener opener,
  Uri server,
  String userId,
) async {
  try {
    return await opener.open(server, userId);
  } on Object catch (e, stackTrace) {
    log(
      'Could not open the chat cache; using memory instead',
      name: 'tinode_flutter_chat',
      error: e,
      stackTrace: stackTrace,
    );
    return ChatStore(ChatDatabase(NativeDatabase.memory()));
  }
}

/// SQLite files in the app's support directory, one per server and user.
final class DeviceChatStoreOpener implements ChatStoreOpener {
  static const _accountsFile = 'tinode_accounts.json';

  @override
  Future<ChatStore> open(Uri server, String userId) async => ChatStore(
    ChatDatabase(
      driftDatabase(
        name: _name(server, userId),
        native: const DriftNativeOptions(
          databaseDirectory: getApplicationSupportDirectory,
        ),
      ),
    ),
  );

  @override
  Future<void> delete(Uri server, String userId) async {
    final base =
        '${(await getApplicationSupportDirectory()).path}'
        '/${_name(server, userId)}.sqlite';
    for (final path in [base, '$base-wal', '$base-shm', '$base-journal']) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

  @override
  Future<String?> lastUser(Uri server) async =>
      (await _accounts())[_serverKey(server)];

  @override
  Future<void> rememberUser(Uri server, String userId) async =>
      _saveAccounts((await _accounts())..[_serverKey(server)] = userId);

  @override
  Future<void> forgetUser(Uri server) async =>
      _saveAccounts((await _accounts())..remove(_serverKey(server)));

  Future<File> _accountsPath() async =>
      File('${(await getApplicationSupportDirectory()).path}/$_accountsFile');

  Future<Map<String, String>> _accounts() async {
    final file = await _accountsPath();
    if (!file.existsSync()) {
      return {};
    }
    try {
      return {
        for (final MapEntry(:key, :value)
            in (jsonDecode(await file.readAsString()) as Map<String, Object?>)
                .entries)
          if (value is String) key: value,
      };
    } on FormatException {
      return {};
    }
  }

  Future<void> _saveAccounts(Map<String, String> accounts) async {
    final file = await _accountsPath();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(accounts));
  }

  static String _name(Uri server, String userId) =>
      userStorageName(server, userId);

  static String _serverKey(Uri server) => '${server.host}_${server.port}';
}

/// A file name for [userId]'s data on [server], from the server's host and
/// port and the user ID, e.g. `tinode_chat_example_com_443_usrAbC`.
String userStorageName(Uri server, String userId) =>
    'tinode_${server.host}_${server.port}_$userId'.replaceAll(
      RegExp('[^A-Za-z0-9_-]'),
      '_',
    );

/// Caches kept in memory for as long as the opener lives: for tests, and
/// for hosts that want no files.
final class MemoryChatStoreOpener implements ChatStoreOpener {
  final _databases = <String, ChatDatabase>{};
  final _users = <String, String>{};

  @override
  Future<ChatStore> open(Uri server, String userId) async => ChatStore(
    _databases.putIfAbsent(
      '$server $userId',
      () => ChatDatabase(NativeDatabase.memory()),
    ),
    ownsDatabase: false,
  );

  @override
  Future<void> delete(Uri server, String userId) async =>
      _databases.remove('$server $userId')?.close();

  @override
  Future<String?> lastUser(Uri server) async => _users['$server'];

  @override
  Future<void> rememberUser(Uri server, String userId) async =>
      _users['$server'] = userId;

  @override
  Future<void> forgetUser(Uri server) async => _users.remove('$server');
}
