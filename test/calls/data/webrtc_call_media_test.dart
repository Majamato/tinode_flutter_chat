import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/data/webrtc_call_media.dart';

void main() {
  test('passes the ICE servers on in the shape WebRTC takes', () {
    expect(
      iceConfiguration(const [
        IceServer(urls: ['stun:stun.example.com']),
        IceServer(
          urls: ['turn:turn.example.com', 'turns:turn.example.com:443'],
          username: 'u',
          credential: 'p',
          credentialType: 'password',
        ),
      ]),
      {
        'iceServers': [
          {
            'urls': ['stun:stun.example.com'],
          },
          {
            'urls': ['turn:turn.example.com', 'turns:turn.example.com:443'],
            'username': 'u',
            'credential': 'p',
            'credentialType': 'password',
          },
        ],
        'sdpSemantics': 'unified-plan',
      },
    );
  });
}
