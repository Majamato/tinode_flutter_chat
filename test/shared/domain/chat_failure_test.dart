import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

void main() {
  test('maps errors to failures', () {
    expect(
      ChatFailure.of(const ServerUnreachableException()),
      ChatFailure.unreachable,
    );
    expect(
      ChatFailure.of(const ConnectionLostException()),
      ChatFailure.connectionLost,
    );
    expect(
      ChatFailure.of(const ConnectionClosedException()),
      ChatFailure.connectionLost,
    );
    expect(
      ChatFailure.of(const ServerException(401, 'auth')),
      ChatFailure.badCredentials,
    );
    expect(
      ChatFailure.of(const ServerException(403, 'denied')),
      ChatFailure.rejected,
    );
    expect(
      ChatFailure.of(const RequestTimeoutException('pub', Duration.zero)),
      ChatFailure.timeout,
    );
    expect(ChatFailure.of(StateError('?')), ChatFailure.unexpected);
  });
}
