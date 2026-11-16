// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_relay.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Takes the pushes the host's push service receives in its background
/// isolate while the app lives in this process (`TinodeMessages`), through
/// the port it names after the server ([pushPortNamesProvider]): the
/// logged-in session handles them on its own connection, so no second
/// login, connection or writer of the cache starts. A suspended session
/// wakes for one grace period to fetch.

@ProviderFor(PushRelay)
final pushRelayProvider = PushRelayProvider._();

/// Takes the pushes the host's push service receives in its background
/// isolate while the app lives in this process (`TinodeMessages`), through
/// the port it names after the server ([pushPortNamesProvider]): the
/// logged-in session handles them on its own connection, so no second
/// login, connection or writer of the cache starts. A suspended session
/// wakes for one grace period to fetch.
final class PushRelayProvider extends $NotifierProvider<PushRelay, void> {
  /// Takes the pushes the host's push service receives in its background
  /// isolate while the app lives in this process (`TinodeMessages`), through
  /// the port it names after the server ([pushPortNamesProvider]): the
  /// logged-in session handles them on its own connection, so no second
  /// login, connection or writer of the cache starts. A suspended session
  /// wakes for one grace period to fetch.
  PushRelayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRelayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRelayHash();

  @$internal
  @override
  PushRelay create() => PushRelay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pushRelayHash() => r'f6c5423ad8555aa43e114a01f470cc023203307b';

/// Takes the pushes the host's push service receives in its background
/// isolate while the app lives in this process (`TinodeMessages`), through
/// the port it names after the server ([pushPortNamesProvider]): the
/// logged-in session handles them on its own connection, so no second
/// login, connection or writer of the cache starts. A suspended session
/// wakes for one grace period to fetch.

abstract class _$PushRelay extends $Notifier<void> {
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
