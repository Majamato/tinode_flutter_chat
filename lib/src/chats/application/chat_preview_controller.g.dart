// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_preview_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The preview of each chat's newest message, by topic, read from the
/// cache: all of them first, then each chat again when its cached messages
/// or members change (`ChatSession.storedChanges`), changes in one turn
/// read once.
///
/// It never asks the server itself: a chat this device isn't attached to
/// gets no message content, only `pres msg`, and the session's latest
/// catch-up fetches the newest messages (and the members a preview needs)
/// into the cache. Until then, or while offline, a chat keeps the preview
/// of its newest cached message.

@ProviderFor(ChatPreviewController)
final chatPreviewControllerProvider = ChatPreviewControllerProvider._();

/// The preview of each chat's newest message, by topic, read from the
/// cache: all of them first, then each chat again when its cached messages
/// or members change (`ChatSession.storedChanges`), changes in one turn
/// read once.
///
/// It never asks the server itself: a chat this device isn't attached to
/// gets no message content, only `pres msg`, and the session's latest
/// catch-up fetches the newest messages (and the members a preview needs)
/// into the cache. Until then, or while offline, a chat keeps the preview
/// of its newest cached message.
final class ChatPreviewControllerProvider
    extends $NotifierProvider<ChatPreviewController, Map<String, ChatPreview>> {
  /// The preview of each chat's newest message, by topic, read from the
  /// cache: all of them first, then each chat again when its cached messages
  /// or members change (`ChatSession.storedChanges`), changes in one turn
  /// read once.
  ///
  /// It never asks the server itself: a chat this device isn't attached to
  /// gets no message content, only `pres msg`, and the session's latest
  /// catch-up fetches the newest messages (and the members a preview needs)
  /// into the cache. Until then, or while offline, a chat keeps the preview
  /// of its newest cached message.
  ChatPreviewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatPreviewControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatPreviewControllerHash();

  @$internal
  @override
  ChatPreviewController create() => ChatPreviewController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ChatPreview> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ChatPreview>>(value),
    );
  }
}

String _$chatPreviewControllerHash() =>
    r'ed6fb222d23fd471ad4729228f04989bb5b7233c';

/// The preview of each chat's newest message, by topic, read from the
/// cache: all of them first, then each chat again when its cached messages
/// or members change (`ChatSession.storedChanges`), changes in one turn
/// read once.
///
/// It never asks the server itself: a chat this device isn't attached to
/// gets no message content, only `pres msg`, and the session's latest
/// catch-up fetches the newest messages (and the members a preview needs)
/// into the cache. Until then, or while offline, a chat keeps the preview
/// of its newest cached message.

abstract class _$ChatPreviewController
    extends $Notifier<Map<String, ChatPreview>> {
  Map<String, ChatPreview> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Map<String, ChatPreview>, Map<String, ChatPreview>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, ChatPreview>, Map<String, ChatPreview>>,
              Map<String, ChatPreview>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The preview of [topic]'s newest cached message, if there is one.

@ProviderFor(chatPreview)
final chatPreviewProvider = ChatPreviewFamily._();

/// The preview of [topic]'s newest cached message, if there is one.

final class ChatPreviewProvider
    extends $FunctionalProvider<ChatPreview?, ChatPreview?, ChatPreview?>
    with $Provider<ChatPreview?> {
  /// The preview of [topic]'s newest cached message, if there is one.
  ChatPreviewProvider._({
    required ChatPreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatPreviewHash();

  @override
  String toString() {
    return r'chatPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatPreview?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatPreview? create(Ref ref) {
    final argument = this.argument as String;
    return chatPreview(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatPreview? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatPreview?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatPreviewHash() => r'e24adad4e19a1ce9a22c80b582c92329ea65c0af';

/// The preview of [topic]'s newest cached message, if there is one.

final class ChatPreviewFamily extends $Family
    with $FunctionalFamilyOverride<ChatPreview?, String> {
  ChatPreviewFamily._()
    : super(
        retry: null,
        name: r'chatPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The preview of [topic]'s newest cached message, if there is one.

  ChatPreviewProvider call(String topic) =>
      ChatPreviewProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatPreviewProvider';
}
