import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';

import 'faulty_database.dart';

/// A [MemoryChatStoreOpener] whose call log sits behind [fault], and whose
/// [openCallLog] throws while [failOpen].
final class FaultyStoreOpener implements ChatStoreOpener {
  final fault = DatabaseFault();
  bool failOpen = false;

  final _stores = MemoryChatStoreOpener();
  late final _log = CallLogDatabase(
    NativeDatabase.memory().interceptWith(fault),
  );

  @override
  Future<CallLog> openCallLog(Uri server, String userId) async {
    if (failOpen) {
      throw InjectedFault();
    }
    return CallLog(_log, ownsDatabase: false);
  }

  @override
  Future<void> deleteCallLog(Uri server, String userId) async {}

  @override
  Future<ChatStore> open(Uri server, String userId) =>
      _stores.open(server, userId);

  @override
  Future<void> delete(Uri server, String userId) =>
      _stores.delete(server, userId);

  @override
  Future<String?> lastUser(Uri server) => _stores.lastUser(server);

  @override
  Future<void> rememberUser(Uri server, String userId) =>
      _stores.rememberUser(server, userId);

  @override
  Future<void> forgetUser(Uri server) => _stores.forgetUser(server);
}
