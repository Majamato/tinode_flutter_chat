// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The server to connect to; `createTinodeContainer` overrides it.

@ProviderFor(tinodeConfig)
final tinodeConfigProvider = TinodeConfigProvider._();

/// The server to connect to; `createTinodeContainer` overrides it.

final class TinodeConfigProvider
    extends $FunctionalProvider<TinodeConfig, TinodeConfig, TinodeConfig>
    with $Provider<TinodeConfig> {
  /// The server to connect to; `createTinodeContainer` overrides it.
  TinodeConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tinodeConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tinodeConfigHash();

  @$internal
  @override
  $ProviderElement<TinodeConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TinodeConfig create(Ref ref) {
    return tinodeConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TinodeConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TinodeConfig>(value),
    );
  }
}

String _$tinodeConfigHash() => r'c472ed6910f96d0db0c41738023df59a1f2322db';

/// The credentials the host passed to `TinodeChat`, if any.

@ProviderFor(initialCredentials)
final initialCredentialsProvider = InitialCredentialsProvider._();

/// The credentials the host passed to `TinodeChat`, if any.

final class InitialCredentialsProvider
    extends
        $FunctionalProvider<
          TinodeCredentials?,
          TinodeCredentials?,
          TinodeCredentials?
        >
    with $Provider<TinodeCredentials?> {
  /// The credentials the host passed to `TinodeChat`, if any.
  InitialCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialCredentialsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialCredentialsHash();

  @$internal
  @override
  $ProviderElement<TinodeCredentials?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TinodeCredentials? create(Ref ref) {
    return initialCredentials(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TinodeCredentials? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TinodeCredentials?>(value),
    );
  }
}

String _$initialCredentialsHash() =>
    r'239bd9b4a4aaccfffa155614bd58c5d9b1b5e93b';

/// How sessions are opened; tests override it with a fake.

@ProviderFor(sessionConnector)
final sessionConnectorProvider = SessionConnectorProvider._();

/// How sessions are opened; tests override it with a fake.

final class SessionConnectorProvider
    extends
        $FunctionalProvider<
          SessionConnector,
          SessionConnector,
          SessionConnector
        >
    with $Provider<SessionConnector> {
  /// How sessions are opened; tests override it with a fake.
  SessionConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionConnectorHash();

  @$internal
  @override
  $ProviderElement<SessionConnector> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionConnector create(Ref ref) {
    return sessionConnector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionConnector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionConnector>(value),
    );
  }
}

String _$sessionConnectorHash() => r'0c68d9602ae12c817494907c983711ac01d065da';

/// How a remembered user's session starts without waiting for the server;
/// tests override it with a fake.

@ProviderFor(sessionRestorer)
final sessionRestorerProvider = SessionRestorerProvider._();

/// How a remembered user's session starts without waiting for the server;
/// tests override it with a fake.

final class SessionRestorerProvider
    extends
        $FunctionalProvider<SessionRestorer, SessionRestorer, SessionRestorer>
    with $Provider<SessionRestorer> {
  /// How a remembered user's session starts without waiting for the server;
  /// tests override it with a fake.
  SessionRestorerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRestorerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRestorerHash();

  @$internal
  @override
  $ProviderElement<SessionRestorer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionRestorer create(Ref ref) {
    return sessionRestorer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRestorer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRestorer>(value),
    );
  }
}

String _$sessionRestorerHash() => r'eac0ace08f5a32165bb754c39507a1ce9532a390';

/// The OS's network reports; tests override it with a fake.

@ProviderFor(networkMonitor)
final networkMonitorProvider = NetworkMonitorProvider._();

/// The OS's network reports; tests override it with a fake.

final class NetworkMonitorProvider
    extends $FunctionalProvider<NetworkMonitor, NetworkMonitor, NetworkMonitor>
    with $Provider<NetworkMonitor> {
  /// The OS's network reports; tests override it with a fake.
  NetworkMonitorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkMonitorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkMonitorHash();

  @$internal
  @override
  $ProviderElement<NetworkMonitor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NetworkMonitor create(Ref ref) {
    return networkMonitor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkMonitor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkMonitor>(value),
    );
  }
}

String _$networkMonitorHash() => r'47c64daf83493f5cd050aebcf45501f974e719ac';
