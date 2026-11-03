// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconnecting_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// True while the client restores a dropped link of the logged-in session.

@ProviderFor(ReconnectingController)
final reconnectingControllerProvider = ReconnectingControllerProvider._();

/// True while the client restores a dropped link of the logged-in session.
final class ReconnectingControllerProvider
    extends $NotifierProvider<ReconnectingController, bool> {
  /// True while the client restores a dropped link of the logged-in session.
  ReconnectingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconnectingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconnectingControllerHash();

  @$internal
  @override
  ReconnectingController create() => ReconnectingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$reconnectingControllerHash() =>
    r'cdf79f7f73c94b3c7412d3c17ca692a146c1cdf2';

/// True while the client restores a dropped link of the logged-in session.

abstract class _$ReconnectingController extends $Notifier<bool> {
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

/// Whether to tell the user the link is being restored: true once
/// [ReconnectingController] has stayed true for [networkSettle], so a blip
/// that heals sooner shows nothing; false as soon as the link is back.

@ProviderFor(ReconnectingNotice)
final reconnectingNoticeProvider = ReconnectingNoticeProvider._();

/// Whether to tell the user the link is being restored: true once
/// [ReconnectingController] has stayed true for [networkSettle], so a blip
/// that heals sooner shows nothing; false as soon as the link is back.
final class ReconnectingNoticeProvider
    extends $NotifierProvider<ReconnectingNotice, bool> {
  /// Whether to tell the user the link is being restored: true once
  /// [ReconnectingController] has stayed true for [networkSettle], so a blip
  /// that heals sooner shows nothing; false as soon as the link is back.
  ReconnectingNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconnectingNoticeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconnectingNoticeHash();

  @$internal
  @override
  ReconnectingNotice create() => ReconnectingNotice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$reconnectingNoticeHash() =>
    r'2f38981ec9472f055260e3b6cbc6b3b6ef700362';

/// Whether to tell the user the link is being restored: true once
/// [ReconnectingController] has stayed true for [networkSettle], so a blip
/// that heals sooner shows nothing; false as soon as the link is back.

abstract class _$ReconnectingNotice extends $Notifier<bool> {
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
