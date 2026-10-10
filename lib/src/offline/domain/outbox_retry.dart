import 'dart:math';

import 'package:tinode_dart_client/tinode_dart_client.dart';

/// How often a transient failure is retried on a live link before the
/// message is marked failed.
const maxSendAttempts = 5;

/// What the outbox does after a request failed.
enum RetryDecision {
  /// The link is down: wait for the next connect.
  waitForConnection,

  /// The server may or may not have taken it: look before sending again.
  reconcile,

  /// Worth another try after a pause.
  retryLater,

  /// The server refused it for good.
  fail,
}

RetryDecision retryDecisionFor(Object error) => switch (error) {
  // No login yet, e.g. right after an offline start.
  ConnectionClosedException() ||
  StateError() => RetryDecision.waitForConnection,
  // An upload or download that found no network; the socket, if it is
  // gone too, stops the outbox anyway.
  ServerUnreachableException() => RetryDecision.retryLater,
  RequestTimeoutException() => RetryDecision.reconcile,
  // Busy, timed out, rate limited, or "attach first" after a lost topic.
  ServerException(:final code)
      when code >= 500 || code == 408 || code == 409 || code == 429 =>
    RetryDecision.retryLater,
  ServerException() => RetryDecision.fail,
  _ => RetryDecision.fail,
};

/// The pause before retry [attempt] (1 for the first): full jitter over a
/// doubling window, capped at a minute.
Duration retryDelay(int attempt, [Random? random]) {
  final cap = min(60, 1 << min(attempt, 6));
  return Duration(
    milliseconds: ((random ?? Random()).nextDouble() * cap * 1000).round(),
  );
}
