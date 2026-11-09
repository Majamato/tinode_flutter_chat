import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/camera_capture.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

part 'send_controller.g.dart';

/// Sending in one chat: loading while a message goes into the outbox, an
/// error when that failed. Only the send button watches it.
///
/// The outbox sends it when the link allows; the chat shows it meanwhile,
/// and marks it failed if the server refuses it.
@riverpod
class SendController extends _$SendController {
  @override
  AsyncValue<void> build(String topic) => const AsyncData(null);

  /// Queues [text] as plain text. Returns whether it was queued, so the
  /// composer clears its field only then. Blank text is not sent.
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) {
      return false;
    }
    state = const AsyncLoading();

    try {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      await session.send(topic, PlainText(trimmed));
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return true;
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return false;
    }
  }

  /// Lets the user pick a photo, video or file from [source]; null when
  /// they cancelled, or when the picker failed (the state says why).
  Future<PickedFile?> pick(AttachmentSource source) async {
    _clearError();
    try {
      return await ref.read(attachmentPickerProvider).pick(source);
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return null;
    }
  }

  /// The photo or video the in-app camera took, as a file to send; it is
  /// also saved to the device's photos, so it outlives the chat. Null when
  /// it can't be read (the state says why).
  Future<PickedFile?> captured(CameraCapture capture) async {
    _clearError();
    try {
      final file = await ref
          .read(attachmentPickerProvider)
          .captured(capture.path, isVideo: capture.isVideo);
      unawaited(
        ref.read(gallerySaverProvider)(capture.path, isVideo: capture.isVideo),
      );
      return file;
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return null;
    }
  }

  /// Forgets an earlier failure, so the composer, which speaks when the
  /// state turns into an error, also tells of the next one.
  void _clearError() {
    if (state is AsyncError) {
      state = const AsyncData(null);
    }
  }

  /// Queues [file] with [caption]. Returns whether it was queued; a file
  /// over the server's limit is refused with `FileTooLargeException`, and a
  /// video too long to fit once compressed with `VideoTooLongException`.
  Future<bool> sendAttachment(PickedFile file, {String caption = ''}) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    try {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      await session.sendAttachment(topic, file, caption: caption);
      if (ref.mounted) {
        state = const AsyncData(null);
      }
      return true;
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return false;
    }
  }
}
