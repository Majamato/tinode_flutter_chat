// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_members_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The members of one open chat: shown from the cache, fetched in full
/// whenever the chat attaches ([sync], called by `ChatController`), and
/// kept current from the topic's live traffic:
///
/// - other members' read and received markers (`info`) raise their
///   counters, and so does a message they send;
/// - a member who joins or leaves (`pres acs`), or a sender not known yet,
///   is fetched alone.
///
/// Channels have none: their followers stay anonymous.

@ProviderFor(ChatMembersController)
final chatMembersControllerProvider = ChatMembersControllerFamily._();

/// The members of one open chat: shown from the cache, fetched in full
/// whenever the chat attaches ([sync], called by `ChatController`), and
/// kept current from the topic's live traffic:
///
/// - other members' read and received markers (`info`) raise their
///   counters, and so does a message they send;
/// - a member who joins or leaves (`pres acs`), or a sender not known yet,
///   is fetched alone.
///
/// Channels have none: their followers stay anonymous.
final class ChatMembersControllerProvider
    extends $NotifierProvider<ChatMembersController, ChatMembers> {
  /// The members of one open chat: shown from the cache, fetched in full
  /// whenever the chat attaches ([sync], called by `ChatController`), and
  /// kept current from the topic's live traffic:
  ///
  /// - other members' read and received markers (`info`) raise their
  ///   counters, and so does a message they send;
  /// - a member who joins or leaves (`pres acs`), or a sender not known yet,
  ///   is fetched alone.
  ///
  /// Channels have none: their followers stay anonymous.
  ChatMembersControllerProvider._({
    required ChatMembersControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatMembersControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMembersControllerHash();

  @override
  String toString() {
    return r'chatMembersControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatMembersController create() => ChatMembersController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMembers value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMembers>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMembersControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMembersControllerHash() =>
    r'9e40fd050f426ed2ad218f707f8355b00c663c1f';

/// The members of one open chat: shown from the cache, fetched in full
/// whenever the chat attaches ([sync], called by `ChatController`), and
/// kept current from the topic's live traffic:
///
/// - other members' read and received markers (`info`) raise their
///   counters, and so does a message they send;
/// - a member who joins or leaves (`pres acs`), or a sender not known yet,
///   is fetched alone.
///
/// Channels have none: their followers stay anonymous.

final class ChatMembersControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatMembersController,
          ChatMembers,
          ChatMembers,
          ChatMembers,
          String
        > {
  ChatMembersControllerFamily._()
    : super(
        retry: null,
        name: r'chatMembersControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The members of one open chat: shown from the cache, fetched in full
  /// whenever the chat attaches ([sync], called by `ChatController`), and
  /// kept current from the topic's live traffic:
  ///
  /// - other members' read and received markers (`info`) raise their
  ///   counters, and so does a message they send;
  /// - a member who joins or leaves (`pres acs`), or a sender not known yet,
  ///   is fetched alone.
  ///
  /// Channels have none: their followers stay anonymous.

  ChatMembersControllerProvider call(String topic) =>
      ChatMembersControllerProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatMembersControllerProvider';
}

/// The members of one open chat: shown from the cache, fetched in full
/// whenever the chat attaches ([sync], called by `ChatController`), and
/// kept current from the topic's live traffic:
///
/// - other members' read and received markers (`info`) raise their
///   counters, and so does a message they send;
/// - a member who joins or leaves (`pres acs`), or a sender not known yet,
///   is fetched alone.
///
/// Channels have none: their followers stay anonymous.

abstract class _$ChatMembersController extends $Notifier<ChatMembers> {
  late final _$args = ref.$arg as String;
  String get topic => _$args;

  ChatMembers build(String topic);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatMembers, ChatMembers>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatMembers, ChatMembers>,
              ChatMembers,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Who sent message [seq] of a group, as its bubble shows it; null for
/// the user's own messages and outside groups, where the chat's title says
/// who it is.

@ProviderFor(messageSender)
final messageSenderProvider = MessageSenderFamily._();

/// Who sent message [seq] of a group, as its bubble shows it; null for
/// the user's own messages and outside groups, where the chat's title says
/// who it is.

final class MessageSenderProvider
    extends $FunctionalProvider<MessageSender?, MessageSender?, MessageSender?>
    with $Provider<MessageSender?> {
  /// Who sent message [seq] of a group, as its bubble shows it; null for
  /// the user's own messages and outside groups, where the chat's title says
  /// who it is.
  MessageSenderProvider._({
    required MessageSenderFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'messageSenderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageSenderHash();

  @override
  String toString() {
    return r'messageSenderProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<MessageSender?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageSender? create(Ref ref) {
    final argument = this.argument as (String, int);
    return messageSender(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageSender? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageSender?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageSenderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageSenderHash() => r'e26e3728508d303d1ee0015025f0dc5e5617d7bc';

/// Who sent message [seq] of a group, as its bubble shows it; null for
/// the user's own messages and outside groups, where the chat's title says
/// who it is.

final class MessageSenderFamily extends $Family
    with $FunctionalFamilyOverride<MessageSender?, (String, int)> {
  MessageSenderFamily._()
    : super(
        retry: null,
        name: r'messageSenderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who sent message [seq] of a group, as its bubble shows it; null for
  /// the user's own messages and outside groups, where the chat's title says
  /// who it is.

  MessageSenderProvider call(String topic, int seq) =>
      MessageSenderProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'messageSenderProvider';
}

/// How far the user's own message [seq] got; null for others' messages.

@ProviderFor(messageReceipt)
final messageReceiptProvider = MessageReceiptFamily._();

/// How far the user's own message [seq] got; null for others' messages.

final class MessageReceiptProvider
    extends
        $FunctionalProvider<MessageReceipt?, MessageReceipt?, MessageReceipt?>
    with $Provider<MessageReceipt?> {
  /// How far the user's own message [seq] got; null for others' messages.
  MessageReceiptProvider._({
    required MessageReceiptFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'messageReceiptProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageReceiptHash();

  @override
  String toString() {
    return r'messageReceiptProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<MessageReceipt?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageReceipt? create(Ref ref) {
    final argument = this.argument as (String, int);
    return messageReceipt(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageReceipt? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageReceipt?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageReceiptProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageReceiptHash() => r'6a3b516c631d535c8a3664b3baaa4680b8f0a88d';

/// How far the user's own message [seq] got; null for others' messages.

final class MessageReceiptFamily extends $Family
    with $FunctionalFamilyOverride<MessageReceipt?, (String, int)> {
  MessageReceiptFamily._()
    : super(
        retry: null,
        name: r'messageReceiptProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How far the user's own message [seq] got; null for others' messages.

  MessageReceiptProvider call(String topic, int seq) =>
      MessageReceiptProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'messageReceiptProvider';
}

/// The other members who read the user's message [seq], and those who only
/// received it.

@ProviderFor(messageReadBy)
final messageReadByProvider = MessageReadByFamily._();

/// The other members who read the user's message [seq], and those who only
/// received it.

final class MessageReadByProvider
    extends
        $FunctionalProvider<
          ({List<ChatMember> delivered, List<ChatMember> read}),
          ({List<ChatMember> delivered, List<ChatMember> read}),
          ({List<ChatMember> delivered, List<ChatMember> read})
        >
    with $Provider<({List<ChatMember> delivered, List<ChatMember> read})> {
  /// The other members who read the user's message [seq], and those who only
  /// received it.
  MessageReadByProvider._({
    required MessageReadByFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'messageReadByProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$messageReadByHash();

  @override
  String toString() {
    return r'messageReadByProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<({List<ChatMember> delivered, List<ChatMember> read})>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ({List<ChatMember> delivered, List<ChatMember> read}) create(Ref ref) {
    final argument = this.argument as (String, int);
    return messageReadBy(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({List<ChatMember> delivered, List<ChatMember> read}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({List<ChatMember> delivered, List<ChatMember> read})
          >(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessageReadByProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messageReadByHash() => r'f1f12dc2b9ba8be073f4066a44c5d8aca401ac5a';

/// The other members who read the user's message [seq], and those who only
/// received it.

final class MessageReadByFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ({List<ChatMember> delivered, List<ChatMember> read}),
          (String, int)
        > {
  MessageReadByFamily._()
    : super(
        retry: null,
        name: r'messageReadByProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The other members who read the user's message [seq], and those who only
  /// received it.

  MessageReadByProvider call(String topic, int seq) =>
      MessageReadByProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'messageReadByProvider';
}

/// Whether message [seq] offers its read-by list: the user's own messages
/// in groups.

@ProviderFor(showsReadBy)
final showsReadByProvider = ShowsReadByFamily._();

/// Whether message [seq] offers its read-by list: the user's own messages
/// in groups.

final class ShowsReadByProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether message [seq] offers its read-by list: the user's own messages
  /// in groups.
  ShowsReadByProvider._({
    required ShowsReadByFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'showsReadByProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$showsReadByHash();

  @override
  String toString() {
    return r'showsReadByProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as (String, int);
    return showsReadBy(ref, argument.$1, argument.$2);
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
    return other is ShowsReadByProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showsReadByHash() => r'9b6c3f762cfdce4e2ee8ff06b30874e3f02204b1';

/// Whether message [seq] offers its read-by list: the user's own messages
/// in groups.

final class ShowsReadByFamily extends $Family
    with $FunctionalFamilyOverride<bool, (String, int)> {
  ShowsReadByFamily._()
    : super(
        retry: null,
        name: r'showsReadByProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether message [seq] offers its read-by list: the user's own messages
  /// in groups.

  ShowsReadByProvider call(String topic, int seq) =>
      ShowsReadByProvider._(argument: (topic, seq), from: this);

  @override
  String toString() => r'showsReadByProvider';
}
