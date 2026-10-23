import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/calls/data/callkit_system_calls.dart';
import 'package:tinode_flutter_chat/src/calls/data/no_system_calls.dart';
import 'package:tinode_flutter_chat/src/calls/data/webrtc_call_media.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_call_texts.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';

part 'call_inputs.g.dart';

/// How a call gets its audio, video and WebRTC link; tests override it
/// with a fake.
@Riverpod(keepAlive: true)
CallMediaFactory callMediaFactory(Ref ref) => WebRtcCallMedia.new;

/// The texts of the system's call screens; `createTinodeContainer`
/// overrides it with the host's.
@Riverpod(keepAlive: true)
SystemCallTexts systemCallTexts(Ref ref) => SystemCallTexts.english;

/// The phone's own call screens, unless the host turned them off; tests
/// override it with a fake.
@Riverpod(keepAlive: true)
SystemCalls systemCalls(Ref ref) =>
    ref.watch(tinodeChatFeaturesProvider).systemCalls
    ? deviceSystemCalls(ref.watch(systemCallTextsProvider))
    : const NoSystemCalls();
