import 'dart:async';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:webrtc_interface/webrtc_interface.dart' show MediaStream;

/// What one call holds while it runs: the attach of its topic, its
/// [CallMedia] and their events, the peer's early network paths and the
/// setup timer.
///
/// [release] lets go of all of it at once. Work started for the call
/// checks [isReleased] after every `await` and stops once it is set.
final class CallResources {
  CallResources(this._session);

  final TinodeSession _session;
  var _released = false;

  Future<bool>? _attached;
  String? _topic;

  CallMedia? _media;
  var _subscriptions = <StreamSubscription<Object?>>[];

  /// The peer's network paths that arrived before its description.
  final _earlyCandidates = <IceCandidate>[];
  var _hasPeerDescription = false;

  Timer? _setupTimer;

  /// True once the call is over; nothing here is held any more.
  bool get isReleased => _released;

  /// Null until [useMedia], and again after [release].
  CallMedia? get media => _media;

  /// Completes with whether the call's topic got attached.
  Future<bool> get attached => _attached ?? Future.value(false);

  /// Attaches [topic] for the call. Completes with false, and detaches
  /// again, if the call was released meanwhile.
  Future<bool> attach(String topic) => _attached = _attach(topic);

  /// Takes over [topic], which an invite check attached already.
  void adopt(String topic) {
    _topic = topic;
    _attached = Future.value(true);
  }

  Future<bool> _attach(String topic) async {
    await _session.attach(topic);
    if (_released) {
      unawaited(_detach(topic));
      return false;
    }
    _topic = topic;
    return true;
  }

  /// Makes [media] the call's and passes its events on until [release].
  void useMedia(
    CallMedia media, {
    required void Function(IceCandidate candidate) onCandidate,
    required void Function(MediaStream stream) onRemoteStream,
    required void Function(CallLinkState link) onLink,
  }) {
    _media = media;
    _subscriptions = [
      media.candidates.listen(onCandidate),
      media.remoteStreams.listen(onRemoteStream),
      media.linkStates.listen(onLink),
    ];
  }

  /// Passes a network path the peer found to the media. Paths that arrive
  /// before the peer's description wait for [peerDescriptionSet].
  Future<void> addPeerCandidate(IceCandidate candidate) async {
    if (!_hasPeerDescription) {
      _earlyCandidates.add(candidate);
      return;
    }
    try {
      await _media?.addCandidate(candidate);
    } on Object {
      // One unusable path is no reason to end the call; others may work.
    }
  }

  /// The media took the peer's description: the paths that waited go in.
  Future<void> peerDescriptionSet() async {
    _hasPeerDescription = true;
    final early = List.of(_earlyCandidates);
    _earlyCandidates.clear();
    for (final candidate in early) {
      await addPeerCandidate(candidate);
    }
  }

  /// Calls [onTimeout] after [timeout], unless [stopSetupTimer] or
  /// [release] comes first.
  void startSetupTimer(Duration timeout, void Function() onTimeout) {
    _setupTimer?.cancel();
    _setupTimer = Timer(timeout, onTimeout);
  }

  void stopSetupTimer() => _setupTimer?.cancel();

  /// Ends the call's hold on everything: the timer, the media and their
  /// events, and the topic.
  void release() {
    if (_released) {
      return;
    }
    _released = true;
    _setupTimer?.cancel();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _subscriptions = [];
    _earlyCandidates.clear();
    if (_media case final media?) {
      _media = null;
      unawaited(media.close().then((_) {}, onError: (_) {}));
    }
    if (_topic case final topic?) {
      _topic = null;
      unawaited(_detach(topic));
    }
  }

  Future<void> _detach(String topic) =>
      _session.detach(topic).then((_) {}, onError: (_) {});
}
