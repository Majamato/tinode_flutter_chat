import 'dart:async';

import 'package:drift/drift.dart';

/// Thrown by a [DatabaseFault] while it is on.
final class InjectedFault implements Exception {
  @override
  String toString() => 'InjectedFault';
}

/// A switch that makes a real database fail: put it in front of an executor
/// with `executor.interceptWith(fault)`. While [failing], [failingWrites] or
/// [failingClose], the matching work throws [InjectedFault] and touches
/// nothing. With [failingAfterBatch] a batch writes, then throws: a failure
/// half way through, for its transaction to roll back. [holdBatches] stops
/// batches until completed, so a test can act in the middle of one, and
/// [batchHeld] tells when one is there.
final class DatabaseFault extends QueryInterceptor {
  /// Every read and write fails.
  bool failing = false;

  /// Writes fail, reads don't.
  bool failingWrites = false;

  /// Closing fails.
  bool failingClose = false;

  /// Each batch throws once it has written.
  bool failingAfterBatch = false;

  /// When set, the next batches wait for it.
  Completer<void>? holdBatches;

  /// Completes when a batch reaches [holdBatches].
  Completer<void> batchHeld = Completer();

  void _read() {
    if (failing) {
      throw InjectedFault();
    }
  }

  void _write() {
    if (failing || failingWrites) {
      throw InjectedFault();
    }
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _read();
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _write();
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _write();
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _write();
    return super.runDelete(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    _write();
    if (holdBatches case final hold?) {
      if (!batchHeld.isCompleted) {
        batchHeld.complete();
      }
      await hold.future;
    }
    await super.runBatched(executor, statements);
    if (failingAfterBatch) {
      throw InjectedFault();
    }
  }

  @override
  Future<void> close(QueryExecutor inner) async {
    if (failingClose) {
      throw InjectedFault();
    }
    return super.close(inner);
  }
}
