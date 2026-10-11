// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_inputs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the per-user caches live; tests override it with memory.

@ProviderFor(chatStoreOpener)
final chatStoreOpenerProvider = ChatStoreOpenerProvider._();

/// Where the per-user caches live; tests override it with memory.

final class ChatStoreOpenerProvider
    extends
        $FunctionalProvider<ChatStoreOpener, ChatStoreOpener, ChatStoreOpener>
    with $Provider<ChatStoreOpener> {
  /// Where the per-user caches live; tests override it with memory.
  ChatStoreOpenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatStoreOpenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatStoreOpenerHash();

  @$internal
  @override
  $ProviderElement<ChatStoreOpener> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatStoreOpener create(Ref ref) {
    return chatStoreOpener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatStoreOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatStoreOpener>(value),
    );
  }
}

String _$chatStoreOpenerHash() => r'79dfc6aa461a2240f7ef096eb5617602c0181f48';

/// How much of each user's chats stays on the device;
/// `createTinodeContainer` overrides it with the host's.

@ProviderFor(tinodeCacheLimits)
final tinodeCacheLimitsProvider = TinodeCacheLimitsProvider._();

/// How much of each user's chats stays on the device;
/// `createTinodeContainer` overrides it with the host's.

final class TinodeCacheLimitsProvider
    extends
        $FunctionalProvider<
          TinodeCacheLimits,
          TinodeCacheLimits,
          TinodeCacheLimits
        >
    with $Provider<TinodeCacheLimits> {
  /// How much of each user's chats stays on the device;
  /// `createTinodeContainer` overrides it with the host's.
  TinodeCacheLimitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tinodeCacheLimitsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tinodeCacheLimitsHash();

  @$internal
  @override
  $ProviderElement<TinodeCacheLimits> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TinodeCacheLimits create(Ref ref) {
    return tinodeCacheLimits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TinodeCacheLimits value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TinodeCacheLimits>(value),
    );
  }
}

String _$tinodeCacheLimitsHash() => r'ac3d0a2bdfcb21c28345977e58d248525cb3c465';
