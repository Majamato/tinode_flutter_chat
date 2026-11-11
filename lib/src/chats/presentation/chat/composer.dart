import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_size_label.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/typing_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/attach_button.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/send_button.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_message.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/message_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_recorder_controller.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_failure.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder_state.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/recording_panel.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_failure_message.dart';

/// Three pieces of glass floating over the messages: the round attach
/// button, the [MessageField] and the round send button. Typing and sending
/// never rebuild it: the button watches both on its
/// own. Typing tells the other members. A failed send, or a refused
/// attachment, shows a snack bar and keeps the text. Its buttons count as
/// the field, so a tap on them leaves the keyboard open.
///
/// The send button's mic records a voice message: the recording panel
/// (delete, pause or resume, send), on one piece of glass, takes the
/// composer's place, growing on the spring, until the recording is sent or
/// deleted; the field keeps its text meanwhile. Hiding the app drops the
/// recording, paused or not.
class Composer extends ConsumerStatefulWidget {
  const Composer({required this.topic, super.key});

  final String topic;

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  /// From the screen's sides.
  static const _side = 8.0;

  final _text = TextEditingController();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _cancelRecording);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _text.dispose();
    super.dispose();
  }

  VoiceRecorderController get _recorder =>
      ref.read(voiceRecorderControllerProvider(widget.topic).notifier);

  Future<void> _record() async {
    final failure = await _recorder.start();
    if (!mounted) {
      return;
    }
    if (failure != null) {
      _showVoiceFailure(failure);
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        TinodeChatStrings.of(context).recordingVoiceMessage,
        Directionality.of(context),
      ),
    );
  }

  Future<void> _sendRecording() async {
    final failure = await _recorder.send();
    if (!mounted) {
      return;
    }
    if (failure != null) {
      _showVoiceFailure(failure);
    } else {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  void _cancelRecording() => unawaited(_recorder.cancel());

  Future<void> _pauseRecording() async {
    final failure = await _recorder.pause();
    _afterPauseOrResume(failure);
  }

  Future<void> _resumeRecording() async {
    final failure = await _recorder.resume();
    _afterPauseOrResume(failure);
  }

  void _afterPauseOrResume(VoiceFailure? failure) {
    if (!mounted) {
      return;
    }
    if (failure != null) {
      _showVoiceFailure(failure);
    } else {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void _showVoiceFailure(VoiceFailure failure) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          voiceFailureMessage(TinodeChatStrings.of(context), failure),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final sent = await ref
        .read(sendControllerProvider(widget.topic).notifier)
        .send(_text.text);
    if (sent && mounted) {
      _text.clear();
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void _onTyped(String _) =>
      ref.read(typingControllerProvider(widget.topic).notifier).typed();

  void _onSubmitted(String _) => unawaited(_send());

  void _onSendState(AsyncValue<void>? previous, AsyncValue<void> next) {
    if (next case AsyncError(:final error) when previous is! AsyncError) {
      final strings = TinodeChatStrings.of(context);
      final message = switch (error) {
        FileTooLargeException(:final limit) => strings.fileTooLargeLimit(
          fileSizeLabel(limit),
        ),
        VideoTooLongException(:final limit) => strings.videoTooLongLimit(
          formatCallDuration(limit),
        ),
        _ => failureMessage(strings, ChatFailure.of(error)),
      };
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sendControllerProvider(widget.topic), _onSendState);
    final recording = ref.watch(
      voiceRecorderControllerProvider(
        widget.topic,
      ).select((s) => s is VoiceRecording),
    );
    final theme = TinodeChatTheme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final body = recording
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: _side),
            child: GlassSurface(
              radius: theme.composerRadius,
              child: RecordingPanel(
                topic: widget.topic,
                onDelete: _cancelRecording,
                onPause: () => unawaited(_pauseRecording()),
                onResume: () => unawaited(_resumeRecording()),
                onSend: () => unawaited(_sendRecording()),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: _side),
            child: TextFieldTapRegion(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 8,
                children: [
                  AttachButton(topic: widget.topic),
                  Expanded(
                    child: MessageField(
                      controller: _text,
                      hintText: TinodeChatStrings.of(context).messageHint,
                      onChanged: _onTyped,
                      onSubmitted: _onSubmitted,
                    ),
                  ),
                  SendButton(
                    topic: widget.topic,
                    text: _text,
                    onSend: _send,
                    onRecord: () => unawaited(_record()),
                  ),
                ],
              ),
            ),
          );
    // AnimatedSize can't run with no duration, so Reduce motion skips it.
    if (still) {
      return body;
    }
    return AnimatedSize(
      duration: theme.springDuration,
      curve: theme.springCurve,
      alignment: Alignment.bottomCenter,
      child: body,
    );
  }
}
