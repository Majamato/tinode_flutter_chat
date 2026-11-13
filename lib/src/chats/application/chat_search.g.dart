// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the user typed in the chat search field, as typed.

@ProviderFor(ChatSearchFilter)
final chatSearchFilterProvider = ChatSearchFilterProvider._();

/// What the user typed in the chat search field, as typed.
final class ChatSearchFilterProvider
    extends $NotifierProvider<ChatSearchFilter, String> {
  /// What the user typed in the chat search field, as typed.
  ChatSearchFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatSearchFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSearchFilterHash();

  @$internal
  @override
  ChatSearchFilter create() => ChatSearchFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$chatSearchFilterHash() => r'd293e52a33f624205680342ee5a0562f2c0f88d1';

/// What the user typed in the chat search field, as typed.

abstract class _$ChatSearchFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The user's chats whose name matches [ChatSearchFilter]; see
/// [ChatMatches].

@ProviderFor(chatSearchResults)
final chatSearchResultsProvider = ChatSearchResultsProvider._();

/// The user's chats whose name matches [ChatSearchFilter]; see
/// [ChatMatches].

final class ChatSearchResultsProvider
    extends $FunctionalProvider<ChatMatches, ChatMatches, ChatMatches>
    with $Provider<ChatMatches> {
  /// The user's chats whose name matches [ChatSearchFilter]; see
  /// [ChatMatches].
  ChatSearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatSearchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatSearchResultsHash();

  @$internal
  @override
  $ProviderElement<ChatMatches> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatMatches create(Ref ref) {
    return chatSearchResults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMatches value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMatches>(value),
    );
  }
}

String _$chatSearchResultsHash() => r'1f9e5fd3ff79ba50f93eb9bba5ce5ab083bed6b4';
