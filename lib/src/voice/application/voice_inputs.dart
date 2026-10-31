import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/voice/data/just_audio_voice_player.dart';
import 'package:tinode_flutter_chat/src/voice/data/record_voice_recorder.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_player.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder.dart';

part 'voice_inputs.g.dart';

/// How a composer records voice messages; tests override it with a fake.
@Riverpod(keepAlive: true)
VoiceRecorderFactory voiceRecorderFactory(Ref ref) => RecordVoiceRecorder.new;

/// How voice messages play; tests override it with a fake.
@Riverpod(keepAlive: true)
VoicePlayerFactory voicePlayerFactory(Ref ref) => JustAudioVoicePlayer.new;
