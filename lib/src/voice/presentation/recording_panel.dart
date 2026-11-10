import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_recorder_controller.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder_state.dart';
import 'package:tinode_flutter_chat/src/voice/presentation/live_voice_waveform.dart';

/// What takes the composer's place while a voice message records in
/// [topic]. On top, a blinking dot, the recorded time and the live
/// waveform; under them, delete ([onDelete]), a wide pause pill ([onPause],
/// or [onResume] while paused, when it shows the mic) and send ([onSend]).
/// Paused, the dot stops and goes muted and the waveform stops. It slides
/// in from the right as it fades in; Reduce motion stills the dot and the
/// entrance. Watches only the time and whether it is paused.
class RecordingPanel extends ConsumerStatefulWidget {
  const RecordingPanel({
    required this.topic,
    required this.onDelete,
    required this.onPause,
    required this.onResume,
    required this.onSend,
    super.key,
  });

  /// The round buttons, and the pill's height.
  static const buttonSize = 48.0;

  final String topic;
  final VoidCallback onDelete;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSend;

  @override
  ConsumerState<RecordingPanel> createState() => _RecordingPanelState();
}

class _RecordingPanelState extends ConsumerState<RecordingPanel>
    with TickerProviderStateMixin {
  late final _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  late final _entering = CurvedAnimation(parent: _enter, curve: Curves.easeOut);

  // The levels so far and those to come, read once: they don't go through
  // the state, so only the waveform repaints for them.
  late final VoiceRecorderController _recorder = ref.read(
    voiceRecorderControllerProvider(widget.topic).notifier,
  );
  late final _initial = List<double>.of(_recorder.levelsSoFar());

  var _still = false;

  bool _pausedIn(VoiceRecorderState s) => s is VoiceRecording && s.paused;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      voiceRecorderControllerProvider(widget.topic).select(_pausedIn),
      (_, paused) => _blinkWhile(on: !paused),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _enter.value = 1;
    } else if (_enter.isDismissed) {
      unawaited(_enter.forward());
    }
    _blinkWhile(
      on: !_pausedIn(ref.read(voiceRecorderControllerProvider(widget.topic))),
    );
  }

  @override
  void dispose() {
    _entering.dispose();
    _enter.dispose();
    _blink.dispose();
    super.dispose();
  }

  /// Blinks the dot while recording, unless motion is reduced.
  void _blinkWhile({required bool on}) {
    if (on && !_still) {
      if (!_blink.isAnimating) {
        unawaited(_blink.repeat());
      }
    } else if (_blink.isAnimating || _blink.value != 0) {
      _blink
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final (elapsed, paused) = ref.watch(
      voiceRecorderControllerProvider(widget.topic).select(
        (s) => s is VoiceRecording
            ? (s.elapsed, s.paused)
            : (Duration.zero, false),
      ),
    );
    final theme = TinodeChatTheme.of(context);
    final strings = TinodeChatStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _entering,
      builder: (context, child) => Opacity(
        opacity: _entering.value,
        child: Transform.translate(
          offset: Offset(12 * (1 - _entering.value), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  FadeTransition(
                    // 1 → .2 → 1 each second, as in the design.
                    opacity: _blink.drive(
                      TweenSequence([
                        TweenSequenceItem(
                          tween: Tween(begin: 1, end: 0.2),
                          weight: 1,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 0.2, end: 1),
                          weight: 1,
                        ),
                      ]),
                    ),
                    child: AnimatedContainer(
                      duration: theme.fadeDuration,
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: paused
                            ? colors.onSurfaceVariant
                            : theme.recordingColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 52),
                    child: Text(
                      voiceClock(elapsed),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiveVoiceWaveform(
                      initial: _initial,
                      levels: _recorder.liveLevels(),
                      running: !paused,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _RoundButton(
                  tooltip: strings.deleteRecording,
                  icon: icons.delete,
                  background: theme.recordingColor.withValues(alpha: 0.12),
                  foreground: theme.recordingColor,
                  onPressed: widget.onDelete,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PausePill(
                    paused: paused,
                    onPressed: paused ? widget.onResume : widget.onPause,
                  ),
                ),
                const SizedBox(width: 10),
                _RoundButton(
                  tooltip: strings.sendVoiceMessage,
                  icon: icons.send,
                  background: theme.actionColor,
                  foreground: theme.onActionColor,
                  onPressed: widget.onSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A [RecordingPanel.buttonSize] circle with an icon.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    style: IconButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      fixedSize: const Size.square(RecordingPanel.buttonSize),
    ),
    icon: Icon(icon),
  );
}

/// The wide pill between delete and send: "Pause", or the mic and
/// "Resume" while [paused].
class _PausePill extends StatelessWidget {
  const _PausePill({required this.paused, required this.onPressed});

  final bool paused;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final theme = TinodeChatTheme.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
        minimumSize: const Size.fromHeight(RecordingPanel.buttonSize),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.composerRadius),
        ),
        textStyle: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      icon: Icon(paused ? icons.microphone : icons.pause),
      label: Text(paused ? strings.resumeRecording : strings.pauseRecording),
    );
  }
}
