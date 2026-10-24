// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_minimized.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user minimized the running call to the call bar, to use the
/// chats meanwhile. Each call starts full screen, and a ringing call always
/// shows full screen; an ended call stays where it was until it goes.

@ProviderFor(CallMinimized)
final callMinimizedProvider = CallMinimizedProvider._();

/// Whether the user minimized the running call to the call bar, to use the
/// chats meanwhile. Each call starts full screen, and a ringing call always
/// shows full screen; an ended call stays where it was until it goes.
final class CallMinimizedProvider
    extends $NotifierProvider<CallMinimized, bool> {
  /// Whether the user minimized the running call to the call bar, to use the
  /// chats meanwhile. Each call starts full screen, and a ringing call always
  /// shows full screen; an ended call stays where it was until it goes.
  CallMinimizedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callMinimizedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callMinimizedHash();

  @$internal
  @override
  CallMinimized create() => CallMinimized();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$callMinimizedHash() => r'c0ca8465c94cc660253c36e448e76cd30a962174';

/// Whether the user minimized the running call to the call bar, to use the
/// chats meanwhile. Each call starts full screen, and a ringing call always
/// shows full screen; an ended call stays where it was until it goes.

abstract class _$CallMinimized extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
