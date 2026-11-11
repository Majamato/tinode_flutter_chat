import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_file.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_playback_controller.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_speed_controller.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_failure_message.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_play_button.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_speed_button.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/voice_waveform.dart';

/// A voice message in its bubble: the play button, the waveform filling
/// as it plays, the duration (or where it stands), while it plays or
/// pauses the speed, which a tap changes for every message, and the
/// [footer]. It
/// shows complete at once, and plays [source] once its file is on this
/// device (see `voiceFileProvider`): a message without one, or [busy] (an
/// upload's progress in the button), doesn't play yet. A tap after a
/// failed download tries again. Watches only its own playback.
class VoiceBubbleContent extends ConsumerWidget {
  const VoiceBubbleContent({
    required this.note,
    required this.own,
    required this.footer,
    this.source,
    this.busy,
    super.key,
  });

  static const width = 232.0;

  final VoiceNote note;
  final VoiceSource? source;

  /// Whether it is the user's own message, on the brand colour.
  final bool own;

  /// The time and status.
  final Widget footer;
  final Widget? busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = this.source;
    final playback = source == null
        ? null
        : ref.watch(
            voicePlaybackControllerProvider.select(
              (p) => p?.key == source.key ? p : null,
            ),
          );
    final speed = playback == null
        ? null
        : ref.watch(voiceSpeedControllerProvider);
    final theme = TinodeChatTheme.of(context);
    // The player's length once it knows, as its progress and seeks use;
    // until then, the message's.
    final duration = switch (playback?.duration) {
      final d? when d > Duration.zero => d,
      _ => note.duration,
    };
    final shown = playback != null && playback.position > Duration.zero
        ? playback.position
        : duration;
    final meta = own ? theme.ownMetaColor : theme.peerMetaColor;
    final file = source == null ? null : ref.watch(voiceFileProvider(source));
    final onPressed = switch ((source, file)) {
      _ when busy != null => null,
      (final source?, AsyncData(value: final file?)) => () => unawaited(
        _toggle(context, ref, source, file, duration),
      ),
      (final source?, AsyncError()) => () => _retry(ref, source),
      _ => null,
    };

    return SizedBox(
      width: width,
      child: Row(
        children: [
          VoicePlayButton(
            playing: playback?.playing ?? false,
            color: own ? theme.ownAccentColor : theme.actionColor,
            iconColor: own ? theme.ownBubbleColor : theme.onActionColor,
            value: voiceClock(duration),
            busy: busy,
            onPressed: onPressed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VoiceWaveform(
                  waveform: note.waveform,
                  progress: playback?.progress ?? 0,
                  duration: duration,
                  speed: speed?.rate ?? 1,
                  playing:
                      playback != null && playback.playing && !playback.loading,
                  playedColor: own ? theme.ownAccentColor : theme.actionColor,
                  unplayedColor: own
                      ? theme.ownAccentColor.withValues(alpha: 0.35)
                      : theme.waveOffColor,
                  onSeek: playback == null || source == null
                      ? null
                      : (fraction) => unawaited(
                          ref
                              .read(voicePlaybackControllerProvider.notifier)
                              .seek(source.key, fraction),
                        ),
                ),
                // As tall with the speed as without, so the bubble keeps its
                // size as playback starts.
                SizedBox(
                  height: VoiceSpeedButton.targetHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shrinks rather than overflow next to the footer, as
                      // with large text.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ExcludeSemantics(
                                child: Text(
                                  voiceClock(shown),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: meta,
                                        fontSize: 12,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ),
                              if (speed != null)
                                VoiceSpeedButton(
                                  speed: speed,
                                  color: meta,
                                  onPressed: () => _cycleSpeed(ref),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      footer,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _cycleSpeed(WidgetRef ref) =>
      unawaited(ref.read(voiceSpeedControllerProvider.notifier).cycle());

  /// Fetches the file again after a failure, e.g. offline.
  static void _retry(WidgetRef ref, VoiceSource source) {
    if (source case RefVoiceSource(ref: final fileRef)) {
      ref.invalidate(attachmentFileProvider(fileRef, keep: true));
    } else {
      ref.invalidate(voiceFileProvider(source));
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    VoiceSource source,
    LocalFile file,
    Duration duration,
  ) async {
    final failure = await ref
        .read(voicePlaybackControllerProvider.notifier)
        .toggle(
          source,
          file,
          duration: duration == Duration.zero ? null : duration,
        );
    if (failure != null && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            voiceFailureMessage(TinodeChatStrings.of(context), failure),
          ),
        ),
      );
    }
  }
}
