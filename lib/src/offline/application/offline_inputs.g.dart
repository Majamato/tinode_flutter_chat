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
