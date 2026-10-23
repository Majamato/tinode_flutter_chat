import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The texts the system's call screens and notifications show, from the
/// host's strings.
final class SystemCallTexts with ValueObject {
  const SystemCallTexts({
    required this.unknownCaller,
    required this.incomingVoiceCall,
    required this.incomingVideoCall,
    required this.outgoingVoiceCall,
    required this.outgoingVideoCall,
    required this.acceptCall,
    required this.declineCall,
    required this.ongoingCall,
    required this.hangUp,
    required this.missedVoiceCall,
    required this.missedVideoCall,
  });

  /// English, for the defaults and tests.
  static const english = SystemCallTexts(
    unknownCaller: 'Unknown caller',
    incomingVoiceCall: 'Incoming voice call',
    incomingVideoCall: 'Incoming video call',
    outgoingVoiceCall: 'Outgoing voice call',
    outgoingVideoCall: 'Outgoing video call',
    acceptCall: 'Accept',
    declineCall: 'Decline',
    ongoingCall: 'Call in progress',
    hangUp: 'Hang up',
    missedVoiceCall: 'Missed voice call',
    missedVideoCall: 'Missed video call',
  );

  final String unknownCaller;
  final String incomingVoiceCall;
  final String incomingVideoCall;
  final String outgoingVoiceCall;
  final String outgoingVideoCall;
  final String acceptCall;
  final String declineCall;
  final String ongoingCall;
  final String hangUp;
  final String missedVoiceCall;
  final String missedVideoCall;

  @override
  List<Object?> get props => [
    unknownCaller,
    incomingVoiceCall,
    incomingVideoCall,
    outgoingVoiceCall,
    outgoingVideoCall,
    acceptCall,
    declineCall,
    ongoingCall,
    hangUp,
    missedVoiceCall,
    missedVideoCall,
  ];
}
