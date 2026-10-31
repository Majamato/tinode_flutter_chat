// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The calls history, read from the cache like the chat list's previews:
/// all calls first, then a chat's again when its cached messages change
/// (`ChatSession.storedChanges`). Only direct chats have calls.
///
/// The cache holds only what this device fetched, so [refresh] fetches the
/// newest messages of the direct chats it is behind on.

@ProviderFor(CallHistoryController)
final callHistoryControllerProvider = CallHistoryControllerProvider._();

/// The calls history, read from the cache like the chat list's previews:
/// all calls first, then a chat's again when its cached messages change
/// (`ChatSession.storedChanges`). Only direct chats have calls.
///
/// The cache holds only what this device fetched, so [refresh] fetches the
/// newest messages of the direct chats it is behind on.
final class CallHistoryControllerProvider
    extends $NotifierProvider<CallHistoryController, CallHistory> {
  /// The calls history, read from the cache like the chat list's previews:
  /// all calls first, then a chat's again when its cached messages change
  /// (`ChatSession.storedChanges`). Only direct chats have calls.
  ///
  /// The cache holds only what this device fetched, so [refresh] fetches the
  /// newest messages of the direct chats it is behind on.
  CallHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callHistoryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callHistoryControllerHash();

  @$internal
  @override
  CallHistoryController create() => CallHistoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CallHistory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CallHistory>(value),
    );
  }
}

String _$callHistoryControllerHash() =>
    r'3aab92498f33901ebe221963cfb98c1216912101';

/// The calls history, read from the cache like the chat list's previews:
/// all calls first, then a chat's again when its cached messages change
/// (`ChatSession.storedChanges`). Only direct chats have calls.
///
/// The cache holds only what this device fetched, so [refresh] fetches the
/// newest messages of the direct chats it is behind on.

abstract class _$CallHistoryController extends $Notifier<CallHistory> {
  CallHistory build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CallHistory, CallHistory>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CallHistory, CallHistory>,
              CallHistory,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// One call of the history, for its row.

@ProviderFor(callHistoryEntry)
final callHistoryEntryProvider = CallHistoryEntryFamily._();

/// One call of the history, for its row.

final class CallHistoryEntryProvider
    extends
        $FunctionalProvider<
          CallHistoryEntry?,
          CallHistoryEntry?,
          CallHistoryEntry?
        >
    with $Provider<CallHistoryEntry?> {
  /// One call of the history, for its row.
  CallHistoryEntryProvider._({
    required CallHistoryEntryFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'callHistoryEntryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$callHistoryEntryHash();

  @override
  String toString() {
    return r'callHistoryEntryProvider'
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
    return callHistoryEntry(ref, argument.$1, argument.$2);
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
    return other is CallHistoryEntryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$callHistoryEntryHash() => r'c4c80651e007411ee565ddcddcec7dd18f491a97';

/// One call of the history, for its row.

final class CallHistoryEntryFamily extends $Family
    with $FunctionalFamilyOverride<CallHistoryEntry?, (String, int)> {
  CallHistoryEntryFamily._()
    : super(
        retry: null,
        name: r'callHistoryEntryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One call of the history, for its row.

  CallHistoryEntryProvider call(String topic, int seq) =>
      CallHistoryEntryProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'callHistoryEntryProvider';
}
