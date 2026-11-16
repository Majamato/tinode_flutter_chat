// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_search.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The call search as the user types ([search]): the calls of the chats
/// whose name matches (see [CallMatches]) in the whole call log, exact
/// matches first, newest first among each. It reads them a page of
/// [callPageSize] at a time, the next ones as the results scroll
/// ([loadMore]), and a changed chat again as the calls history does. It
/// never asks the server, and opens on every call.

@ProviderFor(CallSearchController)
final callSearchControllerProvider = CallSearchControllerProvider._();

/// The call search as the user types ([search]): the calls of the chats
/// whose name matches (see [CallMatches]) in the whole call log, exact
/// matches first, newest first among each. It reads them a page of
/// [callPageSize] at a time, the next ones as the results scroll
/// ([loadMore]), and a changed chat again as the calls history does. It
/// never asks the server, and opens on every call.
final class CallSearchControllerProvider
    extends $NotifierProvider<CallSearchController, CallSearchState> {
  /// The call search as the user types ([search]): the calls of the chats
  /// whose name matches (see [CallMatches]) in the whole call log, exact
  /// matches first, newest first among each. It reads them a page of
  /// [callPageSize] at a time, the next ones as the results scroll
  /// ([loadMore]), and a changed chat again as the calls history does. It
  /// never asks the server, and opens on every call.
  CallSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callSearchControllerHash();

  @$internal
  @override
  CallSearchController create() => CallSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallSearchState>(value),
    );
  }
}

String _$callSearchControllerHash() =>
    r'bf11d30ae67867b0ef642e31b133370c737ffdbe';

/// The call search as the user types ([search]): the calls of the chats
/// whose name matches (see [CallMatches]) in the whole call log, exact
/// matches first, newest first among each. It reads them a page of
/// [callPageSize] at a time, the next ones as the results scroll
/// ([loadMore]), and a changed chat again as the calls history does. It
/// never asks the server, and opens on every call.

abstract class _$CallSearchController extends $Notifier<CallSearchState> {
  CallSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CallSearchState, CallSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CallSearchState, CallSearchState>,
              CallSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// One call the call search found, for its row.

@ProviderFor(callSearchEntry)
final callSearchEntryProvider = CallSearchEntryFamily._();

/// One call the call search found, for its row.

final class CallSearchEntryProvider
    extends
        $FunctionalProvider<
          CallHistoryEntry?,
          CallHistoryEntry?,
          CallHistoryEntry?
        >
    with $Provider<CallHistoryEntry?> {
  /// One call the call search found, for its row.
  CallSearchEntryProvider._({
    required CallSearchEntryFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'callSearchEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$callSearchEntryHash();

  @override
  String toString() {
    return r'callSearchEntryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<CallHistoryEntry?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CallHistoryEntry? create(Ref ref) {
    final argument = this.argument as (String, int);
    return callSearchEntry(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallHistoryEntry? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallHistoryEntry?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CallSearchEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$callSearchEntryHash() => r'eee612a75ebd6b9436d1deedfa32ad92d3bbc162';

/// One call the call search found, for its row.

final class CallSearchEntryFamily extends $Family
    with $FunctionalFamilyOverride<CallHistoryEntry?, (String, int)> {
  CallSearchEntryFamily._()
    : super(
        retry: null,
        name: r'callSearchEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One call the call search found, for its row.

  CallSearchEntryProvider call(String topic, int seq) =>
      CallSearchEntryProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'callSearchEntryProvider';
}
