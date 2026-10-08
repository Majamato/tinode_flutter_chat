import 'dart:async';

import 'package:clock/clock.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_inputs.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_resources.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_failure.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_invite.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/background_policy.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'call_controller.g.dart';

/// How long an ended call stays on screen before it goes away.
const callEndedLinger = Duration(seconds: 2);

/// How long this device waits for a call to connect beyond the server's
/// call timeout before it gives up by itself.
const callSetupMargin = Duration(seconds: 5);

/// Messages fetched to check whether a new message starts a call.
const _inviteCheckPageSize = 16;

/// The call of this device: places calls, rings for incoming ones, and
/// drives the WebRTC link through [CallMedia] as the peer's call events
/// arrive.
///
/// The call's topic stays attached for the whole call, whatever screen is
/// open. Incoming calls arrive as a call message in an attached chat, or,
/// for other chats, as `pres msg` on `me`, after which an *invite check*
/// attaches the chat and reads the new message.
@Riverpod(keepAlive: true)
class CallController extends _$CallController {
  late TinodeSession _session;
  late String _me;
  late CallMediaFactory _mediaFactory;
  late BuildLifetime _lifetime;

  /// What the running call holds; null when no call runs.
  CallResources? _resources;
  Timer? _linger;

  /// Chats with an invite check running.
  final _checking = <String>{};

  /// The latest state, for `onDispose`, where reading `state` is not
  /// allowed.
  ActiveCall? _latest;

  @override
  ActiveCall? build() {
    _lifetime = BuildLifetime(ref);
    final session = ref.watch(activeSessionProvider);
    final me = ref.watch(currentUserIdProvider);
    _mediaFactory = ref.watch(callMediaFactoryProvider);
    listenSelf((_, call) {
      _latest = call;
      ref
          .read(backgroundPolicyProvider.notifier)
          .keepOpen(inCall: call != null && !call.isOver);
    });
    if (session == null || me == null) {
      return null;
    }
    _session = session;
    _me = me;

    final subscriptions = [
      session.messages.listen(_onMessage),
      session.info
          .where((i) => i.event == InfoEvent.call)
          .listen((i) => unawaited(_onCallInfo(i))),
      session.presence
          .where((p) => p.topic == 'me' && p.event == PresenceEvent.message)
          .listen(_onNewMessageElsewhere),
      session.statusChanges.listen(_onStatus),
    ];

    ref.onDispose(() {
      for (final s in subscriptions) {
        unawaited(s.cancel());
      }
      _linger?.cancel();
      // A new session or a logout ends the call; the state goes with it.
      if (_latest case final call? when !call.isOver) {
        _notifyPeer(call, CallEvent.hangUp);
      }
      _release();
      _checking.clear();
    });
    return null;
  }

  /// Calls the peer of the 1:1 [topic]. The OS asks for the microphone
  /// (and camera) first; a refusal ends the call before it reaches the peer.
  Future<void> start(String topic, {required bool audioOnly}) async {
    if (state case final call? when !call.isOver) {
      return;
    }

    final resources = _begin(
      ActiveCall(
        topic: topic,
        direction: CallDirection.outgoing,
        audioOnly: audioOnly,
        stage: CallStage.preparing,
        cameraOn: !audioOnly,
      ),
    );
    final media = _openMedia(resources);
    try {
      final local = await media.open(video: !audioOnly);
      if (resources.isReleased) {
        return;
      }
      _update((c) => c.copyWith(localStream: local));
      if (!await resources.attach(topic)) {
        return;
      }
      final published = await _session.startCall(topic, audioOnly: audioOnly);
      if (resources.isReleased) {
        // Ended while publishing: the peer would ring for nothing.
        _send(topic, published.seq, CallEvent.hangUp);
        return;
      }
      _update((c) => c.copyWith(seq: published.seq, stage: CallStage.calling));
      _startSetupTimer(resources);
    } on Object catch (e) {
      if (!resources.isReleased) {
        _end(failure: CallFailure.of(e), notifyPeer: false);
      }
    }
  }

  /// Takes the ringing call. Opens the microphone (and camera), then tells
  /// the caller, who answers with its WebRTC offer.
  Future<void> accept() async {
    final call = state;
    final seq = call?.seq;
    final resources = _resources;
    if (call == null ||
        seq == null ||
        resources == null ||
        call.stage != CallStage.incoming) {
      return;
    }

    final media = _openMedia(resources);
    _update((c) => c.copyWith(stage: CallStage.connecting, acceptedHere: true));

    try {
      final local = await media.open(video: !call.audioOnly);
      if (resources.isReleased) {
        return;
      }
      _update((c) => c.copyWith(localStream: local));
      // Only an attached session may exchange the WebRTC setup.
      if (!await resources.attached || resources.isReleased) {
        return;
      }
      _session.sendCallEvent(call.topic, seq, CallEvent.accept);
    } on Object catch (e) {
      if (!resources.isReleased) {
        // Hanging up declines the call for the caller.
        _end(failure: CallFailure.of(e), notifyPeer: true);
      }
    }
  }

  /// Refuses the ringing call.
  void decline() => hangUp();

  /// Ends the call, or cancels or declines it before it connected.
  void hangUp() => _end(notifyPeer: true);

  void toggleMicrophone() => _update((c) {
    _resources?.media?.setMicrophoneEnabled(enabled: !c.micOn);
    return c.copyWith(micOn: !c.micOn);
  });

  void toggleCamera() => _update((c) {
    if (c.audioOnly) {
      return c;
    }
    _resources?.media?.setCameraEnabled(enabled: !c.cameraOn);
    return c.copyWith(cameraOn: !c.cameraOn);
  });

  Future<void> switchCamera() async {
    final resources = _resources;
    final media = resources?.media;
    if (resources == null || media == null || (state?.audioOnly ?? true)) {
      return;
    }
    await media.switchCamera();
    if (!resources.isReleased) {
      _update((c) => c.copyWith(frontCamera: !c.frontCamera));
    }
  }

  Future<void> toggleSpeaker() async {
    final call = state;
    if (call == null || call.isOver) {
      return;
    }
    await _setSpeaker(on: !call.speakerOn);
  }

  // Server traffic.

  void _onMessage(DataMessage message) {
    final call = state;
    final update = message.head?.callState;
    if (call != null &&
        !call.isOver &&
        call.seq != null &&
        message.topic == call.topic &&
        message.head?.replacesSeq == call.seq) {
      if (update == CallState.accepted &&
          call.direction == CallDirection.incoming &&
          !call.acceptedHere) {
        _dismiss();
      } else if (update?.isOver ?? false) {
        _end(notifyPeer: false);
      }
      return;
    }
    if (CallInvite.of(message, me: _me) case final invite?) {
      _ring(invite, attached: false);
    }
  }

  /// A new message in a chat this session is not attached to may start a
  /// call: attach the chat and look.
  void _onNewMessageElsewhere(PresMessage presence) {
    final topic = presence.source;
    final seq = presence.seq;
    if (topic != null &&
        seq != null &&
        TopicKind.of(topic) == TopicKind.direct &&
        _checking.add(topic)) {
      unawaited(_checkInvite(topic, seq));
    }
  }

  Future<void> _checkInvite(String topic, int seq) async {
    final session = _session;
    final lifetime = _lifetime;
    try {
      await session.attach(topic);
    } on Object {
      _checking.remove(topic);
      return;
    }
    var kept = false;
    try {
      final page = await session.history(
        topic,
        since: seq,
        limit: _inviteCheckPageSize,
      );
      if (lifetime.isActive) {
        if (CallInvite.findIn(page, seq, me: _me) case final invite?) {
          kept = _ring(invite, attached: true);
        }
      }
    } on Object {
      // A chat we cannot read has no call for us.
    } finally {
      _checking.remove(topic);
      if (!kept) {
        unawaited(_detach(session, topic));
      }
    }
  }

  Future<void> _onCallInfo(InfoMessage info) async {
    final call = state;
    final seq = call?.seq;
    final resources = _resources;
    if (call == null ||
        call.isOver ||
        seq == null ||
        resources == null ||
        info.seq != seq) {
      return;
    }
    final onMe = info.topic == 'me';
    if ((onMe ? info.source : info.topic) != call.topic) {
      return;
    }
    if (onMe) {
      // Another device of this user took or ended the call.
      switch (info.callEvent) {
        case CallEvent.accept when !call.acceptedHere:
          _dismiss();
        case CallEvent.hangUp:
          _end(notifyPeer: false);
        case _:
      }
      return;
    }

    final outgoing = call.direction == CallDirection.outgoing;
    switch (info.callEvent) {
      case CallEvent.ringing when outgoing && call.stage == CallStage.calling:
        _update((c) => c.copyWith(stage: CallStage.ringing));
      case CallEvent.accept when outgoing && call.stage != CallStage.connecting:
        _update((c) => c.copyWith(stage: CallStage.connecting));
        await _offer(resources, call.topic, seq);
      case CallEvent.offer when !outgoing && call.acceptedHere:
        if (info.description case final offer?) {
          await _answer(resources, call.topic, seq, offer);
        }
      case CallEvent.answer when outgoing:
        if (info.description case final answer?) {
          await _acceptAnswer(resources, answer);
        }
      case CallEvent.iceCandidate:
        if (info.candidate case final candidate?) {
          await resources.addPeerCandidate(candidate);
        }
      case CallEvent.hangUp:
        _end(notifyPeer: false);
      case _:
    }
  }

  /// The server ends calls whose session dropped, so a drop ends ours.
  void _onStatus(ConnectionStatus status) {
    if (status is! Connected) {
      _end(failure: CallFailure.connectionLost, notifyPeer: false);
    }
  }

  // WebRTC setup. The caller offers once the callee accepted; each side
  // holds the peer's candidates back until the peer's description is set.

  Future<void> _offer(CallResources resources, String topic, int seq) async {
    try {
      final offer = await resources.media!.createOffer();
      if (!resources.isReleased) {
        _session.sendCallEvent(
          topic,
          seq,
          CallEvent.offer,
          payload: offer.toJson(),
        );
      }
    } on Object catch (e) {
      if (!resources.isReleased) {
        _end(failure: _setupFailure(e), notifyPeer: true);
      }
    }
  }

  Future<void> _answer(
    CallResources resources,
    String topic,
    int seq,
    CallDescription offer,
  ) async {
    try {
      final answer = await resources.media!.answer(offer);
      if (resources.isReleased) {
        return;
      }
      _session.sendCallEvent(
        topic,
        seq,
        CallEvent.answer,
        payload: answer.toJson(),
      );
      await resources.peerDescriptionSet();
    } on Object catch (e) {
      if (!resources.isReleased) {
        _end(failure: _setupFailure(e), notifyPeer: true);
      }
    }
  }

  Future<void> _acceptAnswer(
    CallResources resources,
    CallDescription answer,
  ) async {
    try {
      await resources.media!.acceptAnswer(answer);
      if (!resources.isReleased) {
        await resources.peerDescriptionSet();
      }
    } on Object catch (e) {
      if (!resources.isReleased) {
        _end(failure: _setupFailure(e), notifyPeer: true);
      }
    }
  }

  void _onLocalCandidate(IceCandidate candidate) {
    final call = state;
    if (call != null && call.seq != null) {
      _send(
        call.topic,
        call.seq!,
        CallEvent.iceCandidate,
        payload: candidate.toJson(),
      );
    }
  }

  void _onLink(CallLinkState link) {
    switch (link) {
      case CallLinkState.connected when state?.stage != CallStage.connected:
        _resources?.stopSetupTimer();
        _update(
          (c) =>
              c.copyWith(stage: CallStage.connected, connectedAt: clock.now()),
        );
        if (state case ActiveCall(audioOnly: false)) {
          unawaited(_setSpeaker(on: true));
        }
      case CallLinkState.failed || CallLinkState.closed:
        _end(failure: CallFailure.mediaFailed, notifyPeer: true);
      case CallLinkState.connecting ||
          CallLinkState.connected ||
          CallLinkState.disconnected:
      // A brief disconnect may recover by itself; failed follows if not.
    }
  }

  Future<void> _setSpeaker({required bool on}) async {
    final resources = _resources;
    if (resources == null) {
      return;
    }
    try {
      await resources.media?.setSpeakerOn(on: on);
    } on Object {
      return;
    }
    if (!resources.isReleased) {
      _update((c) => c.copyWith(speakerOn: on));
    }
  }

  // Lifecycle of one call.

  /// Shows the incoming [invite], unless a call is already running.
  /// [attached] says an invite check attached the topic already. Returns
  /// whether the call took over that attach.
  bool _ring(CallInvite invite, {required bool attached}) {
    if (state case final call? when !call.isOver) {
      if (call.topic != invite.topic || call.seq != invite.seq) {
        // Busy: hanging up declines the other call.
        _send(invite.topic, invite.seq, CallEvent.hangUp);
      }
      return false;
    }
    final resources = _begin(
      ActiveCall(
        topic: invite.topic,
        direction: CallDirection.incoming,
        audioOnly: invite.audioOnly,
        stage: CallStage.incoming,
        seq: invite.seq,
        cameraOn: !invite.audioOnly,
      ),
    );
    if (attached) {
      resources.adopt(invite.topic);
    } else {
      // Accepting waits for it.
      unawaited(resources.attach(invite.topic));
    }
    _send(invite.topic, invite.seq, CallEvent.ringing);
    _startSetupTimer(resources);
    return true;
  }

  /// Starts a new call with [call] as its state; returns what it holds.
  CallResources _begin(ActiveCall call) {
    _linger?.cancel();
    _release();
    state = call;
    return _resources = CallResources(_session);
  }

  CallMedia _openMedia(CallResources resources) {
    final media = _mediaFactory(_session.serverInfo.iceServers);
    resources.useMedia(
      media,
      onCandidate: _onLocalCandidate,
      onRemoteStream: (stream) =>
          _update((c) => c.copyWith(remoteStream: stream)),
      onLink: _onLink,
    );
    return media;
  }

  /// Gives up a call that does not connect in time. The server ends an
  /// unanswered call by itself; this covers a lost hang-up or a link that
  /// never comes up.
  void _startSetupTimer(CallResources resources) {
    final timeout =
        (_session.serverInfo.callTimeout ?? const Duration(seconds: 30)) +
        callSetupMargin;
    resources.startSetupTimer(
      timeout,
      () => _end(
        failure: state?.stage == CallStage.connecting
            ? CallFailure.mediaFailed
            : null,
        notifyPeer: true,
      ),
    );
  }

  /// Ends the call: tells the peer if [notifyPeer], releases the media and
  /// the topic, and shows the ended call for [callEndedLinger].
  void _end({required bool notifyPeer, CallFailure? failure}) {
    final call = state;
    if (call == null || call.isOver) {
      return;
    }
    if (notifyPeer) {
      _notifyPeer(call, CallEvent.hangUp);
    }
    _release();
    state = call.copyWith(stage: CallStage.ended, failure: failure);
    _linger = Timer(callEndedLinger, () {
      if (state?.isOver ?? false) {
        state = null;
      }
    });
  }

  /// Ends a call that another device of this user took: nothing to show.
  void _dismiss() {
    _release();
    state = null;
  }

  /// Lets go of what the running call holds, which stops all work started
  /// for it.
  void _release() {
    _resources?.release();
    _resources = null;
  }

  void _notifyPeer(ActiveCall call, CallEvent event) {
    if (call.seq case final seq?) {
      _send(call.topic, seq, event);
    }
  }

  /// Sends a call event the call does not depend on; a closed connection
  /// already ended the call on the server.
  void _send(String topic, int seq, CallEvent event, {Json? payload}) {
    try {
      _session.sendCallEvent(topic, seq, event, payload: payload);
    } on TinodeException {
      // Nothing to do: see above.
    }
  }

  void _update(ActiveCall Function(ActiveCall call) change) {
    if (state case final call? when !call.isOver) {
      state = change(call);
    }
  }

  static Future<void> _detach(TinodeSession session, String topic) =>
      session.detach(topic).then((_) {}, onError: (_) {});

  /// A connection error is reported as such; anything else is WebRTC.
  static CallFailure _setupFailure(Object error) =>
      switch (CallFailure.of(error)) {
        CallFailure.connectionLost => CallFailure.connectionLost,
        _ => CallFailure.mediaFailed,
      };
}

/// Whether the user can call the peer of [topic]: a 1:1 chat they may
/// write to, on a server that takes calls.
@riverpod
bool callsAvailable(Ref ref, String topic) {
  final session = ref.watch(activeSessionProvider);
  // After an offline start the server's ICE servers come with the login.
  ref.watch(currentLoginProvider);
  final chat = ref.watch(
    chatSummaryProvider(
      topic,
    ).select((c) => c == null ? null : (kind: c.kind, canWrite: c.canWrite)),
  );
  return session != null &&
      session.serverInfo.callsEnabled &&
      chat?.kind == TopicKind.direct &&
      (chat?.canWrite ?? false);
}
