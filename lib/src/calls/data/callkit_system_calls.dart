import 'dart:io';

import 'package:flutter_callkit_incoming/entities/entities.dart' as callkit;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart'
    as callkit;
import 'package:tinode_flutter_chat/src/calls/data/no_system_calls.dart';
import 'package:tinode_flutter_chat/src/calls/data/system_call_id.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_call_texts.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';

/// The system's call screens of this device: [CallKitSystemCalls] on
/// Android and iOS, [NoSystemCalls] elsewhere.
SystemCalls deviceSystemCalls(SystemCallTexts texts) =>
    CallKitSystemCalls.supported
    ? CallKitSystemCalls(texts)
    : const NoSystemCalls();

/// [SystemCalls] backed by the `flutter_callkit_incoming` plugin: CallKit
/// on iOS; on Android a self-managed Telecom connection, its incoming call
/// screen, and a foreground service that holds the microphone and camera
/// while a call goes on.
///
/// What a call is (chat, seq, audio only, and how to hang up from the
/// background) travels in the plugin's `extra`, so events name their call
/// even in an isolate that didn't ring it.
final class CallKitSystemCalls implements SystemCalls {
  CallKitSystemCalls(this._texts);

  /// Whether this platform has the plugin.
  static bool get supported => Platform.isAndroid || Platform.isIOS;

  /// Asks Android for what an incoming call screen needs: notifications
  /// (Android 13+) and full screen notifications (Android 14+, which opens
  /// the system settings). iOS asks nothing for calls.
  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid) {
      return;
    }
    await callkit.FlutterCallkitIncoming.requestNotificationPermission(
      <String, Object?>{},
    );
    if (!await callkit.FlutterCallkitIncoming.canUseFullScreenIntent()) {
      await callkit.FlutterCallkitIncoming.requestFullIntentPermission();
    }
  }

  final SystemCallTexts _texts;

  /// Calls this device ended, whose end the plugin reports back as if the
  /// user had ended them.
  final _endedHere = <String>{};

  /// The calls reported here, by system ID: events about the microphone
  /// carry only the ID.
  final _known = <String, SystemCall>{};

  @override
  late final Stream<SystemCallAction> actions = callkit
      .FlutterCallkitIncoming
      .onEvent
      .expand((event) => [?_actionOf(event)]);

  @override
  Future<void> ring(SystemCall call, {required Duration ringFor}) async {
    final id = systemCallId(call.topic, call.seq);
    _known[id] = call;
    if ((await callkit.FlutterCallkitIncoming.activeCalls()).any(
      (c) => c.id == id,
    )) {
      return;
    }
    await callkit.FlutterCallkitIncoming.showCallkitIncoming(
      _params(call, ringFor: ringFor),
    );
  }

  @override
  Future<void> placed(SystemCall call) async {
    _known[systemCallId(call.topic, call.seq)] = call;
    await callkit.FlutterCallkitIncoming.startCall(_params(call));
  }

  @override
  Future<void> acceptedInApp(SystemCall call) async {
    final id = systemCallId(call.topic, call.seq);
    _known[id] = call;
    final params = _params(call);
    if (await _active(id) == null) {
      await callkit.FlutterCallkitIncoming.startCall(params);
      return;
    }
    if (Platform.isAndroid) {
      // There is no accept to request: stop the ringing, then start the
      // call, which keeps the ringing Telecom connection and starts the
      // foreground service.
      await callkit.FlutterCallkitIncoming.hideCallkitIncoming(params);
      await callkit.FlutterCallkitIncoming.startCall(params);
    }
    // On iOS this answers the CallKit call.
    await callkit.FlutterCallkitIncoming.setCallConnected(id);
  }

  @override
  Future<void> connected(String topic, int seq) =>
      callkit.FlutterCallkitIncoming.setCallConnected(systemCallId(topic, seq));

  @override
  Future<void> end(String topic, int seq, {bool missed = false}) async {
    final id = systemCallId(topic, seq);
    final known = _known.remove(id);
    final active = await _active(id);
    if (active != null) {
      _endedHere.add(id);
      await callkit.FlutterCallkitIncoming.endCall(id);
    }
    if (missed && known != null) {
      await callkit.FlutterCallkitIncoming.showMissCallNotification(
        _params(known),
      );
    }
  }

  @override
  Future<void> stopRinging(String topic, int seq, {bool missed = false}) async {
    final id = systemCallId(topic, seq);
    final active = await _active(id);
    if (active == null || active.isAccepted) {
      return;
    }
    _known.remove(id);
    _endedHere.add(id);
    await callkit.FlutterCallkitIncoming.endCall(id);
    if (missed) {
      await callkit.FlutterCallkitIncoming.showMissCallNotification(active);
    }
  }

  @override
  Future<void> setMuted(String topic, int seq, {required bool muted}) =>
      callkit.FlutterCallkitIncoming.muteCall(
        systemCallId(topic, seq),
        isMuted: muted,
      );

  @override
  Future<List<SystemCall>> accepted() async => [
    for (final params in await callkit.FlutterCallkitIncoming.activeCalls())
      if (params.isAccepted) ?systemCallOf(params),
  ].where((call) => call.direction == CallDirection.incoming).toList();

  Future<callkit.CallKitParams?> _active(String id) async {
    for (final params in await callkit.FlutterCallkitIncoming.activeCalls()) {
      if (params.id == id) {
        return params;
      }
    }
    return null;
  }

  SystemCallAction? _actionOf(callkit.CallEvent? event) {
    switch (event) {
      case callkit.CallEventActionCallAccept(:final callKitParams):
        if (systemCallOf(callKitParams) case final call?) {
          return SystemCallAccepted(
            topic: call.topic,
            seq: call.seq,
            audioOnly: call.audioOnly,
          );
        }
      case callkit.CallEventActionCallDecline(:final callKitParams) ||
          callkit.CallEventActionCallEnded(:final callKitParams):
        if (_endedHere.remove(callKitParams.id)) {
          return null;
        }
        if (systemCallOf(callKitParams) case final call?) {
          return SystemCallEnded(topic: call.topic, seq: call.seq);
        }
      case callkit.CallEventActionCallToggleMute(:final id, :final isMuted):
        if (_known[id] case final call?) {
          return SystemCallMuted(
            topic: call.topic,
            seq: call.seq,
            muted: isMuted,
          );
        }
      case _:
    }
    return null;
  }

  callkit.CallKitParams _params(SystemCall call, {Duration? ringFor}) =>
      callkit.CallKitParams(
        id: systemCallId(call.topic, call.seq),
        nameCaller: call.callerName ?? _texts.unknownCaller,
        handle: switch ((call.direction, call.audioOnly)) {
          (CallDirection.incoming, true) => _texts.incomingVoiceCall,
          (CallDirection.incoming, false) => _texts.incomingVideoCall,
          (CallDirection.outgoing, true) => _texts.outgoingVoiceCall,
          (CallDirection.outgoing, false) => _texts.outgoingVideoCall,
        },
        type: call.audioOnly ? 0 : 1,
        duration: ringFor?.inMilliseconds,
        extra: callExtra(call),
        missedCallNotification: callkit.NotificationParams(
          showNotification: true,
          isShowCallback: false,
          subtitle: call.audioOnly
              ? _texts.missedVoiceCall
              : _texts.missedVideoCall,
        ),
        callingNotification: callkit.NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: _texts.ongoingCall,
          callbackText: _texts.hangUp,
        ),
        android: callkit.AndroidParams(
          isShowCallID: true,
          isShowFullLockedScreen: true,
          textAccept: _texts.acceptCall,
          textDecline: _texts.declineCall,
        ),
        ios: callkit.IOSParams(
          handleType: 'generic',
          supportsVideo: true,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          supportsDTMF: false,
          supportsHolding: false,
          supportsGrouping: false,
          supportsUngrouping: false,
          includesCallsInRecents: false,
          audioSessionMode: call.audioOnly ? 'voiceChat' : 'videoChat',
        ),
      );
}

/// What the plugin keeps of [call] in its `extra`.
Map<String, Object?> callExtra(SystemCall call) => {
  'topic': call.topic,
  'seq': call.seq,
  'audioOnly': call.audioOnly,
  'outgoing': call.direction == CallDirection.outgoing,
  'callerName': ?call.callerName,
  if (call.hangUpWith case final hangUp?)
    'hangUp': {
      'server': '${hangUp.server}',
      'apiKey': hangUp.apiKey,
      'userAgent': hangUp.userAgent,
      'token': hangUp.token,
    },
};

/// The call [params] stands for, read back from its `extra`; null for one
/// this package didn't make.
SystemCall? systemCallOf(callkit.CallKitParams params) {
  final extra = params.extra ?? const {};
  final topic = extra['topic'];
  final seq = switch (extra['seq']) {
    final num n => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };
  if (topic is! String || seq == null) {
    return null;
  }
  return SystemCall(
    topic: topic,
    seq: seq,
    direction: _flag(extra['outgoing'])
        ? CallDirection.outgoing
        : CallDirection.incoming,
    audioOnly: _flag(extra['audioOnly']),
    callerName: switch (extra['callerName']) {
      final String name => name,
      _ => null,
    },
    hangUpWith: switch (extra['hangUp']) {
      {
        'server': final String server,
        'apiKey': final String apiKey,
        'userAgent': final String userAgent,
        'token': final String token,
      } =>
        HangUpCredentials(
          server: Uri.parse(server),
          apiKey: apiKey,
          userAgent: userAgent,
          token: token,
        ),
      _ => null,
    },
  );
}

bool _flag(Object? value) => value == true || value == 'true';
