// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The chat list of the logged-in user: shown from the cache first, then
/// synced with the server, kept current from `me` presence and from the
/// messages of attached chats, and synced again after a reconnect.
///
/// It subscribes to the streams before loading, so nothing that arrives
/// during the load is lost. Offline, the cached list stays as it is.

@ProviderFor(ChatListController)
final chatListControllerProvider = ChatListControllerProvider._();

/// The chat list of the logged-in user: shown from the cache first, then
/// synced with the server, kept current from `me` presence and from the
/// messages of attached chats, and synced again after a reconnect.
///
/// It subscribes to the streams before loading, so nothing that arrives
/// during the load is lost. Offline, the cached list stays as it is.
final class ChatListControllerProvider
    extends $NotifierProvider<ChatListController, ChatListState> {
  /// The chat list of the logged-in user: shown from the cache first, then
  /// synced with the server, kept current from `me` presence and from the
  /// messages of attached chats, and synced again after a reconnect.
  ///
  /// It subscribes to the streams before loading, so nothing that arrives
  /// during the load is lost. Offline, the cached list stays as it is.
  ChatListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatListControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatListControllerHash();

  @$internal
  @override
  ChatListController create() => ChatListController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatListState>(value),
    );
  }
}

String _$chatListControllerHash() =>
    r'2c44694269f9881ca42de3b6dcda74501de8ddfc';

/// The chat list of the logged-in user: shown from the cache first, then
/// synced with the server, kept current from `me` presence and from the
/// messages of attached chats, and synced again after a reconnect.
///
/// It subscribes to the streams before loading, so nothing that arrives
/// during the load is lost. Offline, the cached list stays as it is.

abstract class _$ChatListController extends $Notifier<ChatListState> {
  ChatListState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatListState, ChatListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatListState, ChatListState>,
              ChatListState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// One chat of the list. List tiles watch single fields of it.

@ProviderFor(chatSummary)
final chatSummaryProvider = ChatSummaryFamily._();

/// One chat of the list. List tiles watch single fields of it.

final class ChatSummaryProvider
    extends $FunctionalProvider<ChatSummary?, ChatSummary?, ChatSummary?>
    with $Provider<ChatSummary?> {
  /// One chat of the list. List tiles watch single fields of it.
  ChatSummaryProvider._({
    required ChatSummaryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatSummaryHash();

  @override
  String toString() {
    return r'chatSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatSummary?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatSummary? create(Ref ref) {
    final argument = this.argument as String;
    return chatSummary(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatSummary?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatSummaryHash() => r'bac3ada726a18146cdd4f1af113da1652ebf403c';

/// One chat of the list. List tiles watch single fields of it.

final class ChatSummaryFamily extends $Family
    with $FunctionalFamilyOverride<ChatSummary?, String> {
  ChatSummaryFamily._()
    : super(
        retry: null,
        name: r'chatSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One chat of the list. List tiles watch single fields of it.

  ChatSummaryProvider call(String topic) =>
      ChatSummaryProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatSummaryProvider';
}
