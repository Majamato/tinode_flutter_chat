// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One open chat: shows what the cache holds, attaches to the topic,
/// catches up with the server, merges live messages and the outbox, and
/// marks what the user sees as read. Each attach also syncs the chat's
/// members. Detaches when the chat screen closes.

@ProviderFor(ChatController)
final chatControllerProvider = ChatControllerFamily._();

/// One open chat: shows what the cache holds, attaches to the topic,
/// catches up with the server, merges live messages and the outbox, and
/// marks what the user sees as read. Each attach also syncs the chat's
/// members. Detaches when the chat screen closes.
final class ChatControllerProvider
    extends $NotifierProvider<ChatController, ChatState> {
  /// One open chat: shows what the cache holds, attaches to the topic,
  /// catches up with the server, merges live messages and the outbox, and
  /// marks what the user sees as read. Each attach also syncs the chat's
  /// members. Detaches when the chat screen closes.
  ChatControllerProvider._({
    required ChatControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatControllerHash();

  @override
  String toString() {
    return r'chatControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatController create() => ChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatControllerHash() => r'f69a7cd004ab0402e878208bf588e2bc9872cb54';

/// One open chat: shows what the cache holds, attaches to the topic,
/// catches up with the server, merges live messages and the outbox, and
/// marks what the user sees as read. Each attach also syncs the chat's
/// members. Detaches when the chat screen closes.

final class ChatControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatController,
          ChatState,
          ChatState,
          ChatState,
          String
        > {
  ChatControllerFamily._()
    : super(
        retry: null,
        name: r'chatControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One open chat: shows what the cache holds, attaches to the topic,
  /// catches up with the server, merges live messages and the outbox, and
  /// marks what the user sees as read. Each attach also syncs the chat's
  /// members. Detaches when the chat screen closes.

  ChatControllerProvider call(String topic) =>
      ChatControllerProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatControllerProvider';
}

/// One open chat: shows what the cache holds, attaches to the topic,
/// catches up with the server, merges live messages and the outbox, and
/// marks what the user sees as read. Each attach also syncs the chat's
/// members. Detaches when the chat screen closes.

abstract class _$ChatController extends $Notifier<ChatState> {
  late final _$args = ref.$arg as String;
  String get topic => _$args;

  ChatState build(String topic);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatState, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatState, ChatState>,
              ChatState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// One message of an open chat. Each bubble watches its own.

@ProviderFor(chatMessage)
final chatMessageProvider = ChatMessageFamily._();

/// One message of an open chat. Each bubble watches its own.

final class ChatMessageProvider
    extends $FunctionalProvider<ChatMessage?, ChatMessage?, ChatMessage?>
    with $Provider<ChatMessage?> {
  /// One message of an open chat. Each bubble watches its own.
  ChatMessageProvider._({
    required ChatMessageFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'chatMessageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMessageHash();

  @override
  String toString() {
    return r'chatMessageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<ChatMessage?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatMessage? create(Ref ref) {
    final argument = this.argument as (String, int);
    return chatMessage(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMessage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMessage?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessageHash() => r'b1c195cfac36a691eedf6e2d71b7cec02c8dd8e0';

/// One message of an open chat. Each bubble watches its own.

final class ChatMessageFamily extends $Family
    with $FunctionalFamilyOverride<ChatMessage?, (String, int)> {
  ChatMessageFamily._()
    : super(
        retry: null,
        name: r'chatMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One message of an open chat. Each bubble watches its own.

  ChatMessageProvider call(String topic, int seq) =>
      ChatMessageProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'chatMessageProvider';
}

/// One message of an open chat that waits in the outbox.

@ProviderFor(outgoingMessage)
final outgoingMessageProvider = OutgoingMessageFamily._();

/// One message of an open chat that waits in the outbox.

final class OutgoingMessageProvider
    extends
        $FunctionalProvider<
          OutgoingMessage?,
          OutgoingMessage?,
          OutgoingMessage?
        >
    with $Provider<OutgoingMessage?> {
  /// One message of an open chat that waits in the outbox.
  OutgoingMessageProvider._({
    required OutgoingMessageFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'outgoingMessageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$outgoingMessageHash();

  @override
  String toString() {
    return r'outgoingMessageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<OutgoingMessage?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OutgoingMessage? create(Ref ref) {
    final argument = this.argument as (String, String);
    return outgoingMessage(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutgoingMessage? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutgoingMessage?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OutgoingMessageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$outgoingMessageHash() => r'6a5b9bdf1afea93fb43936aaaf133af831c071f4';

/// One message of an open chat that waits in the outbox.

final class OutgoingMessageFamily extends $Family
    with $FunctionalFamilyOverride<OutgoingMessage?, (String, String)> {
  OutgoingMessageFamily._()
    : super(
        retry: null,
        name: r'outgoingMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One message of an open chat that waits in the outbox.

  OutgoingMessageProvider call(String topic, String clientId) =>
      OutgoingMessageProvider._(argument: (topic, clientId), from: this);

  @override
  String toString() => r'outgoingMessageProvider';
}
