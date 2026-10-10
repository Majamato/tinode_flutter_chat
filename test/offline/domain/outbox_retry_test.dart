import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_retry.dart';

void main() {
  test('each failure gets its decision', () {
    expect(
      retryDecisionFor(const ConnectionClosedException()),
      RetryDecision.waitForConnection,
    );
    expect(
      retryDecisionFor(
        const RequestTimeoutException('pub', Duration(seconds: 1)),
      ),
      RetryDecision.reconcile,
    );
    for (final code in [500, 503, 408, 409, 429]) {
      expect(
        retryDecisionFor(ServerException(code, '')),
        RetryDecision.retryLater,
        reason: '$code',
      );
    }
    for (final code in [400, 403, 404, 413]) {
      expect(
        retryDecisionFor(ServerException(code, '')),
        RetryDecision.fail,
        reason: '$code',
      );
    }
    // An upload that found no network is tried again later.
    expect(
      retryDecisionFor(ServerUnreachableException(Exception('offline'))),
      RetryDecision.retryLater,
    );
    // An upload before the login: wait for the connection.
    expect(
      retryDecisionFor(StateError('Log in first.')),
      RetryDecision.waitForConnection,
    );
  });

  test('retry delays grow and stay under a minute', () {
    final random = Random(1);
    for (var attempt = 1; attempt < 20; attempt++) {
      final delay = retryDelay(attempt, random);
      expect(delay, lessThanOrEqualTo(const Duration(minutes: 1)));
      expect(delay, lessThanOrEqualTo(Duration(seconds: 1 << min(attempt, 6))));
    }
  });

  test('client IDs are unique and read back from a head', () {
    final ids = {for (var i = 0; i < 100; i++) newClientId()};
    expect(ids, hasLength(100));
    expect(ids.first, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
    expect(
      clientIdOf(MessageHead.fromJson({clientIdHeadKey: ids.first})),
      ids.first,
    );
    expect(clientIdOf(null), isNull);
    expect(
      clientIdOf(MessageHead.fromJson(const {clientIdHeadKey: 3})),
      isNull,
    );
  });
}
