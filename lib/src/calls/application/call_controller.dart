import 'dart:async';
import 'dart:developer';

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
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/background_policy.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';
import 'package:tinode_flutter_chat/src/shared/application/build_lifetime.dart';

part 'call_controller.g.dart';

/// How long an ended call stays on screen before it goes away.
const callEndedLinger = Duration(seconds: 2);

/// How long a call that lost its connection stays on screen, offering to
/// call again.
const callLostLinger = Duration(seconds: 12);

/// How long a connected call waits for its dropped link to come back
/// before it ends as lost.
const callReconnectTimeout = Duration(seconds: 20);

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
///
/// Each call is reported to the phone's own call screens ([SystemCalls]),
/// and what the user does there comes back here. A call accepted there
/// that this session doesn't hold, e.g. rung by a push while the app was
/// closed, is *accepted from the system*: it joins once the session is
/// connected, if the call still waits.
@Riverpod(keepAlive: true)
class CallController extends _$CallController {
  late TinodeSession _session;
  late String _me;
  late CallMediaFactory _mediaFactory;
  late SystemCalls _systemCalls;
  late TinodeChatFeatures _features;
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
    _systemCalls = ref.watch(systemCallsProvider);
    _features = ref.watch(tinodeChatFeaturesProvider);
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
      _systemCalls.actions.listen(_onSystemAction),
    ];

    ref.onDispose(() {
      for (final s in subscriptions) {
        unawaited(s.cancel());
      }
      _linger?.cancel();
      // A new session or a logout ends the call; the state goes with it.
      if (_latest case final call? when !call.isOver) {
        _notifyPeer(call, CallEvent.hangUp);
        if (call.seq case final seq?) {
          _report((s) => s.end(call.topic, seq));
        }
      }
      _release();
      _checking.clear();
    });
    unawaited(_joinAcceptedAtStart());
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
      _report(
        (s) => s.placed(
          SystemCall(
            topic: topic,
            seq: published.seq,
            direction: CallDirection.outgoing,
            audioOnly: audioOnly,
            callerName: _chatTitle(topic),
          ),
        ),
      );
      _startSetupTimer(resources);
    } on Object catch (e) {
      if (!resources.isReleased) {
        _end(failure: CallFailure.of(e), notifyPeer: false);
      }
    }
  }

  /// Takes the ringing call. Opens the microphone (and camera), then tells
  /// the caller, who answers with its WebRTC offer.
  Future<void> accept() => _accept(inApp: true);

  /// Takes the ringing call, accepted [inApp] or on the system's screen.
  Future<void> _accept({required bool inApp}) async {
    final call = state;
    final seq = call?.seq;
    final resources = _resources;
    if (call == null ||
        seq == null ||
        resources == null ||
        call.stage != CallStage.incoming) {
      return;
    }

    _update((c) => c.copyWith(stage: CallStage.connecting, acceptedHere: true));
    if (inApp) {
      _report(
        (s) => s.acceptedInApp(
          SystemCall(
            topic: call.topic,
            seq: seq,
            direction: CallDirection.incoming,
            audioOnly: call.audioOnly,
            callerName: _chatTitle(call.topic),
          ),
        ),
      );
    }
    await _join(resources, call.topic, seq, audioOnly: call.audioOnly);
  }

  /// Opens the microphone (and camera) for the accepted call [seq], then
  /// tells the caller, who answers with its WebRTC offer.
  Future<void> _join(
    CallResources resources,
    String topic,
    int seq, {
    required bool audioOnly,
  }) async {
    final media = _openMedia(resources);
    try {
      final local = await media.open(video: !audioOnly);
      if (resources.isReleased) {
        return;
      }
      _update((c) => c.copyWith(localStream: local));
      // Only an attached session may exchange the WebRTC setup.
      if (!await resources.attached || resources.isReleased) {
        return;
      }
      _session.sendCallEvent(topic, seq, CallEvent.accept);
    } on Object catch (e) {
      if (!resources.isReleased) {
        // Hanging up declines the call for the caller.
        _end(failure: CallFailure.of(e), notifyPeer: true);
      }
    }
  }

  /// Refuses the ringing call.
  void decline() => hangUp();

  /// Calls the same peer the same way again, from a call that ended.
  Future<void> callAgain() async {
    if (state case final call? when call.isOver) {
      await start(call.topic, audioOnly: call.audioOnly);
    }
  }

  /// Takes an ended call off the screen at once.
  void closeEnded() {
    if (state?.isOver ?? false) {
      _linger?.cancel();
      state = null;
    }
  }

  /// Ends the call, or cancels or declines it before it connected.
  void hangUp() => _end(notifyPeer: true);

  void toggleMicrophone() => _update((c) {
    _resources?.media?.setMicrophoneEnabled(enabled: !c.micOn);
    if (c.seq case final seq?) {
      _report((s) => s.setMuted(c.topic, seq, muted: c.micOn));
    }
    return c.copyWith(micOn: !c.micOn);
  });

  void toggleCamera() => _update((c) {
    if (c.audioOnly) {
      return c;
    }
    _resources?.media?.setCameraEnabled(enabled: !c.cameraOn);
    return c.copyWith(cameraOn: !c.cameraOn);
  });

  /// Swaps the cameras, one swap at a time. The call is
  /// [ActiveCall.switchingCamera] from the request until the media answers
  /// which camera is in use; the new camera's frames may come later.
  Future<void> switchCamera() async {
    final resources = _resources;
    final media = resources?.media;
    final call = state;
    if (resources == null ||
        media == null ||
        call == null ||
        call.isOver ||
        call.audioOnly ||
        call.switchingCamera) {
      return;
    }
    _update((c) => c.copyWith(switchingCamera: true));
    final bool front;
    try {
      front = await media.switchCamera();
    } on Object {
      if (!resources.isReleased) {
        _update((c) => c.copyWith(switchingCamera: false));
      }
      return;
    }
    if (resources.isReleased) {
      return;
    }
    _update((c) => c.copyWith(frontCamera: front, switchingCamera: false));
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

  /// The server ends calls whose session dropped, so a drop ends ours. A
  /// call accepted from the system waits for the session to connect.
  void _onStatus(ConnectionStatus status) {
    if (status is! Connected && !(_resources?.awaitingServer ?? false)) {
      _end(failure: CallFailure.connectionLost, notifyPeer: false);
    }
  }

  // The phone's own call screens.

  void _onSystemAction(SystemCallAction action) {
    final call = state;
    final held =
        call != null &&
        !call.isOver &&
        call.topic == action.topic &&
        call.seq == action.seq;
    switch (action) {
      case SystemCallAccepted() when held:
        unawaited(_accept(inApp: false));
      case SystemCallAccepted(:final topic, :final seq, :final audioOnly):
        _acceptFromSystem(topic, seq, audioOnly: audioOnly);
      case SystemCallEnded() when held:
        hangUp();
      case SystemCallEnded(:final topic, :final seq):
        // Rung by a push while this session was away: tell the caller.
        unawaited(_hangUpUnheld(topic, seq));
      case SystemCallMuted(:final muted) when held && muted == call.micOn:
        toggleMicrophone();
      case SystemCallMuted():
    }
  }

  /// Joins the calls the user accepted on the system's screen before this
  /// session started, e.g. from the lock screen while the app was closed.
  Future<void> _joinAcceptedAtStart() async {
    final lifetime = _lifetime;
    final List<SystemCall> calls;
    try {
      calls = await _systemCalls.accepted();
    } on Object {
      return;
    }
    if (!lifetime.isActive) {
      return;
    }
    for (final call in calls) {
      _acceptFromSystem(call.topic, call.seq, audioOnly: call.audioOnly);
    }
  }

  /// The user accepted call [seq] in [topic] on the system's screen, and
  /// this session didn't know it. The call shows as connecting at once; it
  /// joins once the session is connected and the call is found still
  /// waiting, and ends otherwise.
  void _acceptFromSystem(String topic, int seq, {required bool audioOnly}) {
    if (state case final call? when !call.isOver) {
      if (call.topic != topic || call.seq != seq) {
        // Busy: hanging up declines the other call.
        _send(topic, seq, CallEvent.hangUp);
        _report((s) => s.end(topic, seq));
      }
      return;
    }
    final resources = _begin(
      ActiveCall(
        topic: topic,
        direction: CallDirection.incoming,
        audioOnly: audioOnly,
        stage: CallStage.connecting,
        seq: seq,
        cameraOn: !audioOnly,
        acceptedHere: true,
      ),
    )..awaitingServer = true;
    _startSetupTimer(resources);
    unawaited(_joinFromSystem(resources, topic, seq, audioOnly: audioOnly));
  }

  Future<void> _joinFromSystem(
    CallResources resources,
    String topic,
    int seq, {
    required bool audioOnly,
  }) async {
    final session = _session;
    try {
      if (!await _connected(session, resources) ||
          !await resources.attach(topic)) {
        return;
      }
      final page = await session.history(
        topic,
        since: seq,
        limit: _inviteCheckPageSize,
      );
      if (resources.isReleased) {
        return;
      }
      if (CallInvite.findIn(page, seq, me: _me) == null) {
        // Answered elsewhere, or over: nothing to join.
        _end(notifyPeer: false);
        return;
      }
      resources.awaitingServer = false;
      await _join(resources, topic, seq, audioOnly: audioOnly);
    } on Object catch (e) {
      if (!resources.isReleased) {
        _end(failure: CallFailure.of(e), notifyPeer: true);
      }
    }
  }

  /// Hangs up call [seq] in [topic], which the user declined on the
  /// system's screen though this session doesn't hold it. Best effort: the
  /// server ends an unanswered call by itself.
  Future<void> _hangUpUnheld(String topic, int seq) async {
    final session = _session;
    if (session.status is! Connected) {
      _wakeSession();
      try {
        await session.statusChanges
            .firstWhere((s) => s is Connected)
            .timeout(_callTimeout);
      } on Object {
        return;
      }
    }
    if (_lifetime.isActive && identical(session, _session)) {
      _send(topic, seq, CallEvent.hangUp);
    }
  }

  /// Completes with true once [session] is connected, or with false when
  /// the call ends first.
  static Future<bool> _connected(
    TinodeSession session,
    CallResources resources,
  ) async {
    if (session.status is Connected) {
      return !resources.isReleased;
    }
    final ready = Completer<bool>();
    final subscription = session.statusChanges.listen((status) {
      if (status is Connected && !ready.isCompleted) {
        ready.complete(true);
      }
    });
    unawaited(
      resources.whenReleased.then((_) {
        if (!ready.isCompleted) {
          ready.complete(false);
        }
      }),
    );
    try {
      return await ready.future && !resources.isReleased;
    } finally {
      await subscription.cancel();
    }
  }

  /// Opens a session suspended in the background, which a call from the
  /// system's screen needs.
  void _wakeSession() => ref.read(backgroundPolicyProvider.notifier).wake();

  /// Reports a step of a call to the system's call screens. A failure there
  /// leaves the call to the app's own screens.
  void _report(Future<void> Function(SystemCalls calls) step) {
    unawaited(
      step(_systemCalls).then(
        (_) {},
        onError: (Object e, StackTrace stackTrace) => log(
          'The system call screen failed',
          name: 'tinode_flutter_chat',
          error: e,
          stackTrace: stackTrace,
        ),
      ),
    );
  }

  /// The chat's name as the chat list shows it, for the system's screens;
  /// a list nobody shows isn't loaded for it.
  String? _chatTitle(String topic) => ref.exists(chatListControllerProvider)
      ? ref.read(chatListControllerProvider).byTopic[topic]?.title
      : null;

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
      case CallLinkState.connected when state?.stage == CallStage.connected:
        _resources?.stopReconnectTimer();
        _update((c) => c.copyWith(reconnecting: false));
      case CallLinkState.connected:
        _resources?.stopSetupTimer();
        _update(
          (c) =>
              c.copyWith(stage: CallStage.connected, connectedAt: clock.now()),
        );
        if (state case ActiveCall(:final topic, :final seq?)) {
          _report((s) => s.connected(topic, seq));
        }
        if (state case ActiveCall(audioOnly: false)) {
          unawaited(_setSpeaker(on: true));
        }
      case CallLinkState.failed || CallLinkState.closed:
        _end(
          failure: state?.stage == CallStage.connected
              ? CallFailure.callLost
              : CallFailure.mediaFailed,
          notifyPeer: true,
        );
      case CallLinkState.disconnected when state?.stage == CallStage.connected:
        // A brief disconnect may recover by itself; WebRTC may take long to
        // report it failed, so the call gives up by itself in time.
        _update((c) => c.copyWith(reconnecting: true));
        _resources?.startReconnectTimer(
          callReconnectTimeout,
          () => _end(failure: CallFailure.callLost, notifyPeer: true),
        );
      case CallLinkState.connecting || CallLinkState.disconnected:
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

  /// Shows the incoming [invite], unless a call is already running or the
  /// host turned its kind off. [attached] says an invite check attached the
  /// topic already. Returns whether the call took over that attach.
  bool _ring(CallInvite invite, {required bool attached}) {
    if (!_features.allowsCall(audioOnly: invite.audioOnly)) {
      // Left to the user's other devices: not even declined.
      return false;
    }
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
    _report(
      (s) => s.ring(
        SystemCall(
          topic: invite.topic,
          seq: invite.seq,
          direction: CallDirection.incoming,
          audioOnly: invite.audioOnly,
          callerName: _chatTitle(invite.topic),
        ),
        ringFor: _callTimeout,
      ),
    );
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
    resources.startSetupTimer(
      _callTimeout + callSetupMargin,
      () => _end(
        failure: state?.stage == CallStage.connecting
            ? CallFailure.mediaFailed
            : null,
        notifyPeer: true,
      ),
    );
  }

  /// How long the server lets a call ring unanswered.
  Duration get _callTimeout =>
      _session.serverInfo.callTimeout ?? const Duration(seconds: 30);

  /// Ends the call: tells the peer if [notifyPeer], releases the media and
  /// the topic, and shows the ended call for [callEndedLinger]. An incoming
  /// call that stops ringing without a decline here was missed.
  void _end({required bool notifyPeer, CallFailure? failure}) {
    final call = state;
    if (call == null || call.isOver) {
      return;
    }
    if (notifyPeer) {
      _notifyPeer(call, CallEvent.hangUp);
    }
    if (call.seq case final seq?) {
      final missed = call.stage == CallStage.incoming && !notifyPeer;
      _report((s) => s.end(call.topic, seq, missed: missed));
    }
    _release();
    state = call.copyWith(stage: CallStage.ended, failure: failure);
    final lost =
        failure == CallFailure.callLost ||
        failure == CallFailure.connectionLost;
    _linger = Timer(lost ? callLostLinger : callEndedLinger, () {
      if (state?.isOver ?? false) {
        state = null;
      }
    });
  }

  /// Ends a call that another device of this user took: nothing to show.
  void _dismiss() {
    if (state case ActiveCall(:final topic, :final seq?)) {
      _report((s) => s.end(topic, seq));
    }
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
