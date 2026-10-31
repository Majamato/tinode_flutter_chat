// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_runs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where message [seq] sits in its chat. A bubble rebuilds only when its
/// own position changes, e.g. it stops being the last of a run.

@ProviderFor(messageRun)
final messageRunProvider = MessageRunFamily._();

/// Where message [seq] sits in its chat. A bubble rebuilds only when its
/// own position changes, e.g. it stops being the last of a run.

final class MessageRunProvider
    extends $FunctionalProvider<MessageRun, MessageRun, MessageRun>
    with $Provider<MessageRun> {
  /// Where message [seq] sits in its chat. A bubble rebuilds only when its
  /// own position changes, e.g. it stops being the last of a run.
  MessageRunProvider._({
    required MessageRunFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'messageRunProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageRunHash();

  @override
  String toString() {
    return r'messageRunProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<MessageRun> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageRun create(Ref ref) {
    final argument = this.argument as (String, int);
    return messageRun(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRun value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRun>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageRunProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageRunHash() => r'7c58d410fe9a42baa3dd21f7aa95ca41778e2c50';

/// Where message [seq] sits in its chat. A bubble rebuilds only when its
/// own position changes, e.g. it stops being the last of a run.

final class MessageRunFamily extends $Family
    with $FunctionalFamilyOverride<MessageRun, (String, int)> {
  MessageRunFamily._()
    : super(
        retry: null,
        name: r'messageRunProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Where message [seq] sits in its chat. A bubble rebuilds only when its
  /// own position changes, e.g. it stops being the last of a run.

  MessageRunProvider call(String topic, int seq) =>
      MessageRunProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'messageRunProvider';
}

/// Where the outbox message [clientId] sits in its chat.

@ProviderFor(outgoingRun)
final outgoingRunProvider = OutgoingRunFamily._();

/// Where the outbox message [clientId] sits in its chat.

final class OutgoingRunProvider
    extends $FunctionalProvider<MessageRun, MessageRun, MessageRun>
    with $Provider<MessageRun> {
  /// Where the outbox message [clientId] sits in its chat.
  OutgoingRunProvider._({
    required OutgoingRunFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'outgoingRunProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$outgoingRunHash();

  @override
  String toString() {
    return r'outgoingRunProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<MessageRun> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageRun create(Ref ref) {
    final argument = this.argument as (String, String);
    return outgoingRun(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRun value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRun>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OutgoingRunProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$outgoingRunHash() => r'65e5773d367768b2a4972c682b43520838c6ece8';

/// Where the outbox message [clientId] sits in its chat.

final class OutgoingRunFamily extends $Family
    with $FunctionalFamilyOverride<MessageRun, (String, String)> {
  OutgoingRunFamily._()
    : super(
        retry: null,
        name: r'outgoingRunProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Where the outbox message [clientId] sits in its chat.

  OutgoingRunProvider call(String topic, String clientId) =>
      OutgoingRunProvider._(argument: (topic, clientId), from: this);

  @override
  String toString() => r'outgoingRunProvider';
}

/// The unread messages of every chat but [topic], for its back button.

@ProviderFor(otherUnread)
final otherUnreadProvider = OtherUnreadFamily._();

/// The unread messages of every chat but [topic], for its back button.

final class OtherUnreadProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// The unread messages of every chat but [topic], for its back button.
  OtherUnreadProvider._({
    required OtherUnreadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'otherUnreadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$otherUnreadHash();

  @override
  String toString() {
    return r'otherUnreadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as String;
    return otherUnread(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OtherUnreadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$otherUnreadHash() => r'105cc70ca4479e14f1e1efd16032e811a4c7090c';

/// The unread messages of every chat but [topic], for its back button.

final class OtherUnreadFamily extends $Family
    with $FunctionalFamilyOverride<int, String> {
  OtherUnreadFamily._()
    : super(
        retry: null,
        name: r'otherUnreadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The unread messages of every chat but [topic], for its back button.

  OtherUnreadProvider call(String topic) =>
      OtherUnreadProvider._(argument: topic, from: this);

  @override
  String toString() => r'otherUnreadProvider';
}

/// The unread messages of every chat that isn't muted, for the tab bar.

@ProviderFor(totalUnread)
final totalUnreadProvider = TotalUnreadProvider._();

/// The unread messages of every chat that isn't muted, for the tab bar.

final class TotalUnreadProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// The unread messages of every chat that isn't muted, for the tab bar.
  TotalUnreadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalUnreadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalUnreadHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return totalUnread(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$totalUnreadHash() => r'c7833b54abdac4cda111c45fc4280aa0bd3023ad';

/// Whether anyone in [topic] is typing, for the typing bubble.

@ProviderFor(anyoneTyping)
final anyoneTypingProvider = AnyoneTypingFamily._();

/// Whether anyone in [topic] is typing, for the typing bubble.

final class AnyoneTypingProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether anyone in [topic] is typing, for the typing bubble.
  AnyoneTypingProvider._({
    required AnyoneTypingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'anyoneTypingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$anyoneTypingHash();

  @override
  String toString() {
    return r'anyoneTypingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return anyoneTyping(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AnyoneTypingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$anyoneTypingHash() => r'59011def687e76baa4d93d76dea28c6069bc4e45';

/// Whether anyone in [topic] is typing, for the typing bubble.

final class AnyoneTypingFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  AnyoneTypingFamily._()
    : super(
        retry: null,
        name: r'anyoneTypingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether anyone in [topic] is typing, for the typing bubble.

  AnyoneTypingProvider call(String topic) =>
      AnyoneTypingProvider._(argument: topic, from: this);

  @override
  String toString() => r'anyoneTypingProvider';
}
