import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/call_record.dart';

void main() {
  test('reads the call from the message head', () {
    expect(CallRecord.fromHead(null), isNull);
    expect(CallRecord.fromHead(const MessageHead(mime: 'text/plain')), isNull);
    expect(
      CallRecord.fromHead(
        const MessageHead(callState: CallState.started, audioOnly: true),
      ),
      const CallRecord(state: CallState.started, audioOnly: true),
    );
  });

  test('an update keeps voice-only and the known duration', () {
    const started = CallRecord(state: CallState.started, audioOnly: true);
    final finished = started
        .updatedBy(const CallRecord(state: CallState.accepted))
        .updatedBy(
          const CallRecord(
            state: CallState.finished,
            duration: Duration(seconds: 61),
          ),
        );

    expect(
      finished,
      const CallRecord(
        state: CallState.finished,
        audioOnly: true,
        duration: Duration(seconds: 61),
      ),
    );
  });
}
