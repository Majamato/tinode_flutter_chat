// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_policy.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Suspends the session a while after the app is hidden and resumes it
/// when the app is shown again. During a call the session stays open: the
/// grace starts when the call ends.

@ProviderFor(BackgroundPolicy)
final backgroundPolicyProvider = BackgroundPolicyProvider._();

/// Suspends the session a while after the app is hidden and resumes it
/// when the app is shown again. During a call the session stays open: the
/// grace starts when the call ends.
final class BackgroundPolicyProvider
    extends $NotifierProvider<BackgroundPolicy, void> {
  /// Suspends the session a while after the app is hidden and resumes it
  /// when the app is shown again. During a call the session stays open: the
  /// grace starts when the call ends.
  BackgroundPolicyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundPolicyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundPolicyHash();

  @$internal
  @override
  BackgroundPolicy create() => BackgroundPolicy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backgroundPolicyHash() => r'0584fd5ce373d79cfbc17347cb52cb25e58d0417';

/// Suspends the session a while after the app is hidden and resumes it
/// when the app is shown again. During a call the session stays open: the
/// grace starts when the call ends.

abstract class _$BackgroundPolicy extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
