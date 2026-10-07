import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/calls/data/webrtc_call_media.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';

part 'call_inputs.g.dart';

/// How a call gets its audio, video and WebRTC link; tests override it
/// with a fake.
@Riverpod(keepAlive: true)
CallMediaFactory callMediaFactory(Ref ref) => WebRtcCallMedia.new;
