// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A message search as the user types, over the messages of the chat named
/// [topic] kept on this device. It waits for the input to settle and drops
/// answers to older input. It needs no network: the server has no message
/// search.

@ProviderFor(MessageSearchController)
final messageSearchControllerProvider = MessageSearchControllerFamily._();

/// A message search as the user types, over the messages of the chat named
/// [topic] kept on this device. It waits for the input to settle and drops
/// answers to older input. It needs no network: the server has no message
/// search.
final class MessageSearchControllerProvider
    extends $NotifierProvider<MessageSearchController, MessageSearchState> {
  /// A message search as the user types, over the messages of the chat named
  /// [topic] kept on this device. It waits for the input to settle and drops
  /// answers to older input. It needs no network: the server has no message
  /// search.
  MessageSearchControllerProvider._({
    required MessageSearchControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'messageSearchControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageSearchControllerHash();

  @override
  String toString() {
    return r'messageSearchControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MessageSearchController create() => MessageSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageSearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageSearchControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageSearchControllerHash() =>
    r'424fc614cad4ebb6273722c79c1e556dc702cb5c';

/// A message search as the user types, over the messages of the chat named
/// [topic] kept on this device. It waits for the input to settle and drops
/// answers to older input. It needs no network: the server has no message
/// search.

final class MessageSearchControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MessageSearchController,
          MessageSearchState,
          MessageSearchState,
          MessageSearchState,
          String
        > {
  MessageSearchControllerFamily._()
    : super(
        retry: null,
        name: r'messageSearchControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A message search as the user types, over the messages of the chat named
  /// [topic] kept on this device. It waits for the input to settle and drops
  /// answers to older input. It needs no network: the server has no message
  /// search.

  MessageSearchControllerProvider call(String topic) =>
      MessageSearchControllerProvider._(argument: topic, from: this);

  @override
  String toString() => r'messageSearchControllerProvider';
}

/// A message search as the user types, over the messages of the chat named
/// [topic] kept on this device. It waits for the input to settle and drops
/// answers to older input. It needs no network: the server has no message
/// search.

abstract class _$MessageSearchController extends $Notifier<MessageSearchState> {
  late final _$args = ref.$arg as String;
  String get topic => _$args;

  MessageSearchState build(String topic);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MessageSearchState, MessageSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MessageSearchState, MessageSearchState>,
              MessageSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
