import 'package:flutter/material.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/chat_time_format.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// How a call shows in its bubble and in the calls history.
extension CallRecordTexts on CallRecord {
  /// Its direction and kind, e.g. "Outgoing voice call".
  String title(TinodeChatStrings strings, {required bool outgoing}) =>
      switch ((outgoing, audioOnly)) {
        (true, true) => strings.outgoingVoiceCall,
        (true, false) => strings.outgoingVideoCall,
        (false, true) => strings.incomingVoiceCall,
        (false, false) => strings.incomingVideoCall,
      };

  /// How it went: its length, or why it didn't happen.
  String status(TinodeChatStrings strings, {required bool outgoing}) =>
      switch (state) {
        CallState.finished => formatCallDuration(duration ?? Duration.zero),
        CallState.missed =>
          outgoing ? strings.callNoAnswer : strings.callMissed,
        CallState.declined => strings.callDeclined,
        CallState.disconnected || CallState.busy => strings.callNotConnected,
        CallState.started ||
        CallState.accepted ||
        CallState.unknown => strings.callInProgress,
      };

  /// An arrow for its direction, bent when it didn't happen.
  IconData icon(TinodeChatIcons icons, {required bool outgoing}) =>
      switch ((outgoing, failed)) {
        (true, false) => icons.outgoingCall,
        (false, false) => icons.incomingCall,
        (true, true) => icons.cancelledCall,
        (false, true) => icons.missedCall,
      };
}
