import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:webrtc_interface/webrtc_interface.dart' show MediaStream;

/// The configuration of an `RTCPeerConnection` that uses [servers].
Map<String, Object?> iceConfiguration(List<IceServer> servers) => {
  'iceServers': [
    for (final server in servers)
      {
        'urls': server.urls,
        'username': ?server.username,
        'credential': ?server.credential,
        'credentialType': ?server.credentialType,
      },
  ],
  'sdpSemantics': 'unified-plan',
};

/// [CallMedia] backed by the `flutter_webrtc` plugin.
final class WebRtcCallMedia implements CallMedia {
  WebRtcCallMedia(this._iceServers);

  final List<IceServer> _iceServers;
  final _candidates = StreamController<IceCandidate>.broadcast();
  final _remoteStreams = StreamController<MediaStream>.broadcast();
  final _linkStates = StreamController<CallLinkState>.broadcast();
  MediaStream? _local;
  webrtc.RTCPeerConnection? _connection;

  @override
  Stream<IceCandidate> get candidates => _candidates.stream;

  @override
  Stream<MediaStream> get remoteStreams => _remoteStreams.stream;

  @override
  Stream<CallLinkState> get linkStates => _linkStates.stream;

  @override
  Future<MediaStream> open({required bool video}) async {
    try {
      return _local = await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video ? {'facingMode': 'user'} : false,
      });
    } on Object catch (e) {
      // The plugin reports a refusal only as text.
      throw CallMediaException(
        permissionDenied: '$e'.toLowerCase().contains('permission'),
        cause: e,
      );
    }
  }

  @override
  Future<CallDescription> createOffer() async {
    final connection = await _connect();
    final offer = await connection.createOffer();
    await connection.setLocalDescription(offer);
    return _description(offer);
  }

  @override
  Future<CallDescription> answer(CallDescription offer) async {
    final connection = await _connect();
    await connection.setRemoteDescription(
      webrtc.RTCSessionDescription(offer.sdp, offer.type),
    );
    final answer = await connection.createAnswer();
    await connection.setLocalDescription(answer);
    return _description(answer);
  }

  @override
  Future<void> acceptAnswer(CallDescription answer) async =>
      _connection?.setRemoteDescription(
        webrtc.RTCSessionDescription(answer.sdp, answer.type),
      );

  @override
  Future<void> addCandidate(IceCandidate candidate) async =>
      _connection?.addCandidate(
        webrtc.RTCIceCandidate(
          candidate.candidate,
          candidate.sdpMid,
          candidate.sdpMLineIndex,
        ),
      );

  @override
  void setMicrophoneEnabled({required bool enabled}) {
    for (final track
        in _local?.getAudioTracks() ?? const <webrtc.MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  @override
  void setCameraEnabled({required bool enabled}) {
    for (final track
        in _local?.getVideoTracks() ?? const <webrtc.MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_local?.getVideoTracks().firstOrNull case final track?) {
      await webrtc.Helper.switchCamera(track);
    }
  }

  @override
  Future<void> setSpeakerOn({required bool on}) =>
      webrtc.Helper.setSpeakerphoneOn(on);

  @override
  Future<void> close() async {
    final local = _local;
    final connection = _connection;
    _local = null;
    _connection = null;
    for (final track
        in local?.getTracks() ?? const <webrtc.MediaStreamTrack>[]) {
      await track.stop();
    }
    await local?.dispose();
    await connection?.close();
    await _candidates.close();
    await _remoteStreams.close();
    await _linkStates.close();
  }

  /// Creates the peer connection and adds the opened media to it.
  Future<webrtc.RTCPeerConnection> _connect() async {
    final connection = await webrtc.createPeerConnection(
      iceConfiguration(_iceServers),
    );
    connection
      ..onIceCandidate = (candidate) {
        if (candidate.candidate case final line? when line.isNotEmpty) {
          _candidates.add(
            IceCandidate(
              candidate: line,
              sdpMid: candidate.sdpMid,
              sdpMLineIndex: candidate.sdpMLineIndex,
            ),
          );
        }
      }
      ..onTrack = (event) {
        if (event.streams.firstOrNull case final stream?) {
          _remoteStreams.add(stream);
        }
      }
      ..onConnectionState = (state) => _linkStates.add(_linkState(state));
    if (_local case final local?) {
      for (final track in local.getTracks()) {
        await connection.addTrack(track, local);
      }
    }
    return _connection = connection;
  }

  static CallDescription _description(webrtc.RTCSessionDescription d) =>
      CallDescription(type: d.type ?? '', sdp: d.sdp ?? '');

  static CallLinkState _linkState(webrtc.RTCPeerConnectionState state) =>
      switch (state) {
        webrtc.RTCPeerConnectionState.RTCPeerConnectionStateNew ||
        webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting =>
          CallLinkState.connecting,
        webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
          CallLinkState.connected,
        webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
          CallLinkState.disconnected,
        webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
          CallLinkState.failed,
        webrtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed =>
          CallLinkState.closed,
      };
}
