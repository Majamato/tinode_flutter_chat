import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'attachment_file.g.dart';

/// The file [fileRef] names, on this device: from the cache, or downloaded
/// into it once, however many widgets watch it. Images and photos given
/// by ref watch it.
///
/// A failed download, e.g. offline, is an error; it loads again on the
/// next connect.
@riverpod
Future<LocalFile> attachmentFile(Ref ref, String fileRef) async {
  final session = ref.watch(activeSessionProvider);
  if (session == null) {
    throw const ConnectionLostException();
  }
  try {
    return await session.fetchFile(fileRef);
  } on Object {
    if (ref.mounted) {
      final retry = session.statusChanges
          .where((status) => status is Connected)
          .listen((_) => ref.invalidateSelf());
      ref.onDispose(() => unawaited(retry.cancel()));
    }
    rethrow;
  }
}
