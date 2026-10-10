import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';

part 'outgoing_attachment_providers.g.dart';

/// How far the upload of message [clientId]'s attachment got, from 0 to 1;
/// null before it starts. Only the outgoing bubble's progress ring watches
/// it.
@riverpod
class UploadProgressController extends _$UploadProgressController {
  @override
  double? build(String topic, String clientId) {
    final session = ref.watch(activeSessionProvider);
    if (session == null) {
      return null;
    }
    final events = session.outbox.where((e) => e.topic == topic).listen((
      event,
    ) {
      switch (event) {
        case UploadProgress(clientId: final id, :final fraction)
            when id == clientId:
          state = fraction;
        case OutgoingDiscarded(clientId: final id) when id == clientId:
          state = null;
        case _:
          break;
      }
    });
    ref.onDispose(() => unawaited(events.cancel()));
    return null;
  }
}

/// The staged copy of an outgoing attachment, for its bubble; null once
/// it is gone.
@riverpod
Future<LocalFile?> stagedFile(Ref ref, String stagedId) async =>
    ref.watch(activeSessionProvider)?.stagedFile(stagedId);
