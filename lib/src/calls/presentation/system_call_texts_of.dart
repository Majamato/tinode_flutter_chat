import 'package:tinode_flutter_chat/src/calls/domain/system_call_texts.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The texts of the phone's call screens, from the host's [strings].
SystemCallTexts systemCallTextsOf(TinodeChatStrings strings) => SystemCallTexts(
  unknownCaller: strings.unknownCaller,
  incomingVoiceCall: strings.incomingVoiceCall,
  incomingVideoCall: strings.incomingVideoCall,
  outgoingVoiceCall: strings.outgoingVoiceCall,
  outgoingVideoCall: strings.outgoingVideoCall,
  acceptCall: strings.acceptCall,
  declineCall: strings.declineCall,
  ongoingCall: strings.ongoingCall,
  hangUp: strings.hangUp,
  missedVoiceCall: strings.missedVoiceCall,
  missedVideoCall: strings.missedVideoCall,
);
