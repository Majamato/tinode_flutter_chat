import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_inputs.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_playback_controller.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_failure.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder_state.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_waveform.dart';

part 'voice_recorder_controller.g.dart';

/// Recording a voice message in one chat's composer: [start], maybe
/// [pause] and [resume], then [send] or [cancel]. Sending goes through the
/// chat's `SendController`, so its failures show where a file's would. The
/// recording is dropped when the composer goes and when a call starts; at
/// `VoiceNote.maxDuration` of recorded time it is sent. The time counts
/// only what was recorded, not the pauses.
///
/// The levels go to [liveLevels] as they come, outside the state, so only
/// the live waveform repaints for them.
@riverpod
class VoiceRecorderController extends _$VoiceRecorderController {
  /// How often the clock is checked, so each second shows as it ends,
  /// after a resume too.
  static const _tickInterval = Duration(milliseconds: 250);

  VoiceRecorder? _recorder;
  StreamSubscription<double>? _levels;
  Timer? _ticker;

  /// Whether a recording is under way, paused or not.
  var _active = false;

  /// The recorded time before the stretch running since [_runningSince];
  /// all of it while paused.
  Duration _banked = Duration.zero;
  DateTime? _runningSince;

  /// The levels so far, in dBFS.
  final _dbfs = <double>[];
  final _live = StreamController<double>.broadcast();

  /// Set while [start] waits for the recorder, so a second tap does
  /// nothing.
  bool _starting = false;

  @override
  VoiceRecorderState build(String topic) {
    ref
      ..listen(
        callControllerProvider.select((call) => call != null && !call.isOver),
        (_, inCall) {
          if (inCall) {
            unawaited(cancel());
          }
        },
      )
      ..onDispose(() {
        final recording = _active;
        _stopTicking();
        unawaited(_live.close());
        final recorder = _recorder;
        _recorder = null;
        if (recorder != null) {
          unawaited(_release(recorder, cancel: recording));
        }
      });
    return const VoiceIdle();
  }

  /// The levels of the recording so far, in dBFS, one per
  /// `voiceSampleInterval` recorded.
  List<double> get levelsSoFar => UnmodifiableListView(_dbfs);

  /// Each level, in dBFS, as it comes while recording.
  Stream<double> get liveLevels => _live.stream;

  /// The recorded time so far, without the pauses.
  Duration get _recorded {
    final since = _runningSince;
    return since == null ? _banked : _banked + clock.now().difference(since);
  }

  /// Starts recording, after any voice message playing stops. Refused
  /// during a call and without the microphone.
  Future<VoiceFailure?> start() async {
    if (_starting || state is VoiceRecording) {
      return null;
    }
    final call = ref.read(callControllerProvider);
    if (call != null && !call.isOver) {
      return VoiceFailure.duringCall;
    }
    _starting = true;
    try {
      final recorder = _recorder ??= ref.read(voiceRecorderFactoryProvider)();
      if (!await recorder.hasPermission()) {
        return VoiceFailure.microphoneDenied;
      }
      if (!ref.mounted) {
        return null;
      }
      await ref.read(voicePlaybackControllerProvider.notifier).stop();
      await recorder.start();
      if (!ref.mounted) {
        return null;
      }
      _dbfs.clear();
      _levels = recorder.levels.listen((dbfs) {
        _dbfs.add(dbfs);
        _live.add(dbfs);
      });
      _active = true;
      _banked = Duration.zero;
      _runningSince = clock.now();
      _ticker = Timer.periodic(_tickInterval, (_) => _tick());
      state = const VoiceRecording(Duration.zero);
      return null;
    } on Object {
      return VoiceFailure.recorderFailed;
    } finally {
      _starting = false;
    }
  }

  /// Pauses the recording: the clock stops, and so do the levels.
  Future<VoiceFailure?> pause() async {
    final recorder = _recorder;
    final now = state;
    if (recorder == null || !_active || now is! VoiceRecording || now.paused) {
      return null;
    }
    final since = _runningSince;
    final banked = _banked;
    // The time stops as the user taps, not once the recorder answers.
    _banked = _recorded;
    _runningSince = null;
    state = VoiceRecording(_wholeSeconds(_banked), paused: true);
    try {
      await recorder.pause();
      return null;
    } on Object {
      if (_active && _runningSince == null) {
        _banked = banked;
        _runningSince = since;
        if (ref.mounted) {
          state = VoiceRecording(_wholeSeconds(_recorded));
        }
      }
      return VoiceFailure.recorderFailed;
    }
  }

  /// Carries on a paused recording.
  Future<VoiceFailure?> resume() async {
    final recorder = _recorder;
    final now = state;
    if (recorder == null || !_active || now is! VoiceRecording || !now.paused) {
      return null;
    }
    try {
      await recorder.resume();
    } on Object {
      return VoiceFailure.recorderFailed;
    }
    if (!_active || !ref.mounted) {
      return null;
    }
    _runningSince = clock.now();
    state = VoiceRecording(_wholeSeconds(_banked));
    return null;
  }

  /// Stops and queues the recording, paused or not; one under
  /// `VoiceNote.minDuration` is dropped instead.
  Future<VoiceFailure?> send() async {
    final recorder = _recorder;
    if (recorder == null || !_active) {
      return null;
    }
    final elapsed = _recorded;
    final waveform = voicePreviewOf([
      for (final dbfs in _dbfs) amplitudeOfDbfs(dbfs),
    ]);
    _stopTicking();
    state = const VoiceIdle();

    final PickedFile? stopped;
    try {
      stopped = await recorder.stop();
    } on Object {
      return VoiceFailure.recorderFailed;
    }
    if (stopped == null) {
      return VoiceFailure.recorderFailed;
    }
    final recording = stopped;
    if (elapsed < VoiceNote.minDuration) {
      await _quietly(() => recorder.delete(recording));
      return VoiceFailure.tooShort;
    }
    final note = VoiceNote(
      duration: elapsed > VoiceNote.maxDuration
          ? VoiceNote.maxDuration
          : elapsed,
      waveform: waveform,
    );
    if (ref.mounted) {
      await ref
          .read(sendControllerProvider(topic).notifier)
          .sendAttachment(recording.withVoice(note));
    }
    await _quietly(() => recorder.delete(recording));
    return null;
  }

  /// Stops and drops the recording.
  Future<void> cancel() async {
    final recorder = _recorder;
    if (recorder == null || !_active) {
      return;
    }
    _stopTicking();
    if (ref.mounted) {
      state = const VoiceIdle();
    }
    await _quietly(recorder.cancel);
  }

  void _tick() {
    if (!_active || _runningSince == null || !ref.mounted) {
      return;
    }
    final elapsed = _recorded;
    if (elapsed >= VoiceNote.maxDuration) {
      unawaited(send());
      return;
    }
    final shown = VoiceRecording(_wholeSeconds(elapsed));
    if (state != shown) {
      state = shown;
    }
  }

  static Duration _wholeSeconds(Duration d) => Duration(seconds: d.inSeconds);

  void _stopTicking() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_levels?.cancel());
    _levels = null;
    _active = false;
    _banked = Duration.zero;
    _runningSince = null;
  }

  static Future<void> _release(
    VoiceRecorder recorder, {
    required bool cancel,
  }) async {
    if (cancel) {
      await _quietly(recorder.cancel);
    }
    await _quietly(recorder.dispose);
  }

  /// Cleaning up a temporary recording must not fail the send.
  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Left in the temporary directory, which the OS clears.
    }
  }
}
