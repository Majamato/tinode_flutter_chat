import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/camera_capture.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
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

  /// Copies [file] in and reads it, ready to send, while its preview shows;
  /// null when it is refused (over the limit) or can't be read (the state
  /// says why). Says nothing to the send button: the preview shows this.
  Future<OutgoingAttachment?> stage(PickedFile file) async {
    _clearError();
    try {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      return await session.stageAttachment(file);
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return null;
    }
  }

  /// Whether a video's part can be chosen before sending it.
  bool canTrimVideos() =>
      ref.read(activeSessionProvider)?.canTrimVideos ?? false;

  /// The longest part of the video [file], of [duration], that can be sent.
  Duration maxClip(PickedFile file, Duration duration) => ref
      .read(tinodeAttachmentLimitsProvider)
      .maxClip(
        fileBytes: file.length,
        duration: duration,
        serverLimit: ref
            .read(activeSessionProvider)
            ?.serverInfo
            .maxFileUploadSize,
      );

  /// Stills of the video [file], to choose its part by.
  Stream<Uint8List?> videoFrames(
    PickedFile file, {
    required int count,
    required Duration duration,
  }) =>
      ref
          .read(activeSessionProvider)
          ?.videoFrames(file, count: count, duration: duration) ??
      const Stream.empty();

  /// What [stage] returned, to send only its [range].
  Future<OutgoingAttachment> trim(
    OutgoingAttachment attachment,
    VideoTrim range,
  ) async =>
      await ref.read(activeSessionProvider)?.trimStaged(attachment, range) ??
      attachment.trimmed(range);

  /// Queues what [stage] returned, with [caption]. Returns whether it was
  /// queued. Never loading, so neither a message on its way nor another
  /// attachment holds it up.
  Future<bool> sendStaged(
    OutgoingAttachment attachment, {
    String caption = '',
  }) async {
    _clearError();
    try {
      final session = ref.read(activeSessionProvider);
      if (session == null) {
        throw const ConnectionLostException();
      }
      await session.sendStaged(topic, attachment, caption: caption);
      return true;
    } on Object catch (e, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
      return false;
    }
  }

  /// Forgets what [stage] returned, once its preview closed without
  /// sending it.
  Future<void> discardStaged(OutgoingAttachment attachment) async {
    if (ref.mounted) {
      await ref.read(activeSessionProvider)?.discardStaged(attachment);
    }
  }

  /// Queues [file] with [caption], all at once, showing as loading
  /// meanwhile: for a voice message, which has no preview. Returns whether
  /// it was queued; a file over the limit is refused with
  /// `FileTooLargeException`.
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
