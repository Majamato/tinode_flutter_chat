import 'dart:async';

import 'package:drift/drift.dart';

/// Every test container opens its own in-memory cache, which drift would
/// warn about as one database opened twice.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
