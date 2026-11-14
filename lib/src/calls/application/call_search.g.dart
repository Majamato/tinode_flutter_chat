// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the user typed in the call search field, as typed.

@ProviderFor(CallSearchFilter)
final callSearchFilterProvider = CallSearchFilterProvider._();

/// What the user typed in the call search field, as typed.
final class CallSearchFilterProvider
    extends $NotifierProvider<CallSearchFilter, String> {
  /// What the user typed in the call search field, as typed.
  CallSearchFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callSearchFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callSearchFilterHash();

  @$internal
  @override
  CallSearchFilter create() => CallSearchFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$callSearchFilterHash() => r'123e69ea2feba6766a4249a2e68d2eb4bef3eec2';

/// What the user typed in the call search field, as typed.

abstract class _$CallSearchFilter extends $Notifier<String> {
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

/// The calls of the history whose chat's name matches [CallSearchFilter];
/// see [CallMatches].

@ProviderFor(callSearchResults)
final callSearchResultsProvider = CallSearchResultsProvider._();

/// The calls of the history whose chat's name matches [CallSearchFilter];
/// see [CallMatches].

final class CallSearchResultsProvider
    extends $FunctionalProvider<CallMatches, CallMatches, CallMatches>
    with $Provider<CallMatches> {
  /// The calls of the history whose chat's name matches [CallSearchFilter];
  /// see [CallMatches].
  CallSearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callSearchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callSearchResultsHash();

  @$internal
  @override
  $ProviderElement<CallMatches> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CallMatches create(Ref ref) {
    return callSearchResults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallMatches value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallMatches>(value),
    );
  }
}

String _$callSearchResultsHash() => r'25c0061ea2fa1385f89b9ca5cb57d0659474e32c';
