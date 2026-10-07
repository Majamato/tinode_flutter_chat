import 'dart:async';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:webrtc_interface/webrtc_interface.dart' show MediaStream;

/// A [MediaStream] that only has an ID; enough for the call logic, which
/// passes streams on without reading them.
final class FakeMediaStream implements MediaStream {
  FakeMediaStream(this.id);

  @override
  final String id;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A scripted [CallMedia]: it records every call in [log], and tests push
/// what WebRTC would report with [emitCandidate], [emitRemote] and
/// [emitLink].
final class FakeCallMedia implements CallMedia {
  FakeCallMedia([this.iceServers = const []]);

  final List<IceServer> iceServers;

  /// Every call, e.g. `open video`, `offer` or `candidate c1`.
  final log = <String>[];

  /// When set, `open` throws it.
  CallMediaException? failOpen;

  /// When set, `open` waits for it before answering.
  Completer<void>? holdOpen;

  final local = FakeMediaStream('local');
  final remote = FakeMediaStream('remote');
  bool isClosed = false;

  final _candidates = StreamController<IceCandidate>.broadcast(sync: true);
  final _remoteStreams = StreamController<MediaStream>.broadcast(sync: true);
  final _linkStates = StreamController<CallLinkState>.broadcast(sync: true);

  void emitCandidate(String candidate) =>
      _candidates.add(IceCandidate(candidate: candidate, sdpMLineIndex: 0));

  void emitRemote() => _remoteStreams.add(remote);

  void emitLink(CallLinkState state) => _linkStates.add(state);

  @override
  Stream<IceCandidate> get candidates => _candidates.stream;

  @override
  Stream<MediaStream> get remoteStreams => _remoteStreams.stream;

  @override
  Stream<CallLinkState> get linkStates => _linkStates.stream;

  @override
  Future<MediaStream> open({required bool video}) async {
    log.add('open ${video ? 'video' : 'audio'}');
    await holdOpen?.future;
    if (failOpen case final error?) {
      throw error;
    }
    return local;
  }

  @override
  Future<CallDescription> createOffer() async {
    log.add('offer');
    return const CallDescription(type: 'offer', sdp: 'local offer');
  }

  @override
  Future<CallDescription> answer(CallDescription offer) async {
    log.add('answer ${offer.sdp}');
    return const CallDescription(type: 'answer', sdp: 'local answer');
  }

  @override
  Future<void> acceptAnswer(CallDescription answer) async =>
      log.add('acceptAnswer ${answer.sdp}');

  @override
  Future<void> addCandidate(IceCandidate candidate) async =>
      log.add('candidate ${candidate.candidate}');

  @override
  void setMicrophoneEnabled({required bool enabled}) =>
      log.add('mic ${enabled ? 'on' : 'off'}');

  @override
  void setCameraEnabled({required bool enabled}) =>
      log.add('camera ${enabled ? 'on' : 'off'}');

  @override
  Future<void> switchCamera() async => log.add('switchCamera');

  @override
  Future<void> setSpeakerOn({required bool on}) async =>
      log.add('speaker ${on ? 'on' : 'off'}');

  @override
  Future<void> close() async {
    log.add('close');
    isClosed = true;
  }
}

/// A [CallMediaFactory] that keeps every [FakeCallMedia] it creates.
final class FakeCallMediaFactory {
  final created = <FakeCallMedia>[];

  /// What the next media's `open` throws, if anything.
  CallMediaException? failOpen;

  FakeCallMedia get last => created.last;

  CallMedia call(List<IceServer> iceServers) {
    final media = FakeCallMedia(iceServers)..failOpen = failOpen;
    created.add(media);
    return media;
  }
}
