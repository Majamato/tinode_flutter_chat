import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_failure.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';

void main() {
  test('maps errors to failures', () {
    const failures = {
      CallMediaException(permissionDenied: true): CallFailure.permissionDenied,
      CallMediaException(permissionDenied: false): CallFailure.mediaFailed,
      ServerException(486, 'busy here'): CallFailure.busy,
      ServerException(403, 'forbidden'): CallFailure.unavailable,
      ServerException(501, 'not implemented'): CallFailure.unavailable,
      ConnectionClosedException('gone'): CallFailure.connectionLost,
      ServerException(500, 'oops'): CallFailure.unexpected,
    };
    for (final MapEntry(key: error, value: failure) in failures.entries) {
      expect(CallFailure.of(error), failure, reason: '$error');
    }
    expect(CallFailure.of(StateError('x')), CallFailure.unexpected);
  });
}
