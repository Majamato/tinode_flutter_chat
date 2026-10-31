import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_failure.dart';

/// The text that explains [failure] to the user.
String voiceFailureMessage(TinodeChatStrings strings, VoiceFailure failure) =>
    switch (failure) {
      VoiceFailure.microphoneDenied => strings.microphoneDeniedForVoice,
      VoiceFailure.duringCall => strings.cannotRecordDuringCall,
      VoiceFailure.tooShort => strings.voiceMessageTooShort,
      VoiceFailure.recorderFailed => strings.recorderFailed,
      VoiceFailure.cannotPlay => strings.cannotPlayVoiceMessage,
    };
