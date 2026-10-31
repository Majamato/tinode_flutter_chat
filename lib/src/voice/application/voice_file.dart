import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/application/outgoing_attachment_providers.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';

part 'voice_file.g.dart';

/// The recording [source] holds, on this device: a received one is
/// downloaded among the kept files once, when its bubble shows; one of the
/// user's is there since it was recorded. Playback only ever opens this
/// file, never the server's. Null when a staged copy is gone; an error
/// when the download failed, until the next connect.
@riverpod
Future<LocalFile?> voiceFile(Ref ref, VoiceSource source) => switch (source) {
  RefVoiceSource(ref: final fileRef) => ref.watch(
    attachmentFileProvider(fileRef, keep: true).future,
  ),
  StagedVoiceSource(:final stagedId) => ref.watch(
    stagedFileProvider(stagedId).future,
  ),
  InlineVoiceSource(:final bytes) => Future.value(LocalFile.inMemory(bytes)),
};
