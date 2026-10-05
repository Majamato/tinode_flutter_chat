import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Tells async work started by one provider build whether that build is
/// still current.
///
/// In Riverpod 3.1 `ref.mounted` stays true when a provider rebuilds, so a
/// load started by an old build could overwrite the new build's state.
/// Create one per build and check [isActive] after every `await`.
final class BuildLifetime {
  BuildLifetime(Ref ref) {
    ref.onDispose(() => _active = false);
  }

  var _active = true;

  /// False once the build that created this was disposed or replaced.
  bool get isActive => _active;
}
