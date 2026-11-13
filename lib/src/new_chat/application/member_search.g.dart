// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the user typed in the add members field, as typed.

@ProviderFor(MemberFilter)
final memberFilterProvider = MemberFilterProvider._();

/// What the user typed in the add members field, as typed.
final class MemberFilterProvider
    extends $NotifierProvider<MemberFilter, String> {
  /// What the user typed in the add members field, as typed.
  MemberFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberFilterHash();

  @$internal
  @override
  MemberFilter create() => MemberFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$memberFilterHash() => r'2ceb8a6ea8fa6112e67b865090def3397073d54f';

/// What the user typed in the add members field, as typed.

abstract class _$MemberFilter extends $Notifier<String> {
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

/// The suggested members whose name matches [MemberFilter]; see
/// [MemberSuggestions].

@ProviderFor(memberSuggestions)
final memberSuggestionsProvider = MemberSuggestionsProvider._();

/// The suggested members whose name matches [MemberFilter]; see
/// [MemberSuggestions].

final class MemberSuggestionsProvider
    extends
        $FunctionalProvider<
          MemberSuggestions,
          MemberSuggestions,
          MemberSuggestions
        >
    with $Provider<MemberSuggestions> {
  /// The suggested members whose name matches [MemberFilter]; see
  /// [MemberSuggestions].
  MemberSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberSuggestionsHash();

  @$internal
  @override
  $ProviderElement<MemberSuggestions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MemberSuggestions create(Ref ref) {
    return memberSuggestions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberSuggestions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberSuggestions>(value),
    );
  }
}

String _$memberSuggestionsHash() => r'a2f65b8cf5533e4d63939751f9579fe702af8697';

/// The server's search for members, without the people
/// [memberSuggestionsProvider] shows.

@ProviderFor(memberSearch)
final memberSearchProvider = MemberSearchProvider._();

/// The server's search for members, without the people
/// [memberSuggestionsProvider] shows.

final class MemberSearchProvider
    extends
        $FunctionalProvider<
          MemberSearchState,
          MemberSearchState,
          MemberSearchState
        >
    with $Provider<MemberSearchState> {
  /// The server's search for members, without the people
  /// [memberSuggestionsProvider] shows.
  MemberSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberSearchHash();

  @$internal
  @override
  $ProviderElement<MemberSearchState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MemberSearchState create(Ref ref) {
    return memberSearch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberSearchState>(value),
    );
  }
}

String _$memberSearchHash() => r'4a354c290247f854936eca7013cbf3ad971e9479';
