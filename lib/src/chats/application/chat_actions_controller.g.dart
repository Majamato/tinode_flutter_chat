// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_actions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the chat info screen does to one chat: deleting or leaving it, and
/// removing members. Loading while one runs, an error when it failed.
/// They need the link: offline they fail with a lost connection.

@ProviderFor(ChatActionsController)
final chatActionsControllerProvider = ChatActionsControllerFamily._();

/// What the chat info screen does to one chat: deleting or leaving it, and
/// removing members. Loading while one runs, an error when it failed.
/// They need the link: offline they fail with a lost connection.
final class ChatActionsControllerProvider
    extends $NotifierProvider<ChatActionsController, AsyncValue<void>> {
  /// What the chat info screen does to one chat: deleting or leaving it, and
  /// removing members. Loading while one runs, an error when it failed.
  /// They need the link: offline they fail with a lost connection.
  ChatActionsControllerProvider._({
    required ChatActionsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatActionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatActionsControllerHash();

  @override
  String toString() {
    return r'chatActionsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatActionsController create() => ChatActionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatActionsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatActionsControllerHash() =>
    r'3d3a1d2c42fc41d7941d824a51c7ad3c0df3c302';

/// What the chat info screen does to one chat: deleting or leaving it, and
/// removing members. Loading while one runs, an error when it failed.
/// They need the link: offline they fail with a lost connection.

final class ChatActionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatActionsController,
          AsyncValue<void>,
          AsyncValue<void>,
          AsyncValue<void>,
          String
        > {
  ChatActionsControllerFamily._()
    : super(
        retry: null,
        name: r'chatActionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What the chat info screen does to one chat: deleting or leaving it, and
  /// removing members. Loading while one runs, an error when it failed.
  /// They need the link: offline they fail with a lost connection.

  ChatActionsControllerProvider call(String topic) =>
      ChatActionsControllerProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatActionsControllerProvider';
}

/// What the chat info screen does to one chat: deleting or leaving it, and
/// removing members. Loading while one runs, an error when it failed.
/// They need the link: offline they fail with a lost connection.

abstract class _$ChatActionsController extends $Notifier<AsyncValue<void>> {
  late final _$args = ref.$arg as String;
  String get topic => _$args;

  AsyncValue<void> build(String topic);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Why the last action on the chat failed, if it did.

@ProviderFor(chatActionFailure)
final chatActionFailureProvider = ChatActionFailureFamily._();

/// Why the last action on the chat failed, if it did.

final class ChatActionFailureProvider
    extends $FunctionalProvider<ChatFailure?, ChatFailure?, ChatFailure?>
    with $Provider<ChatFailure?> {
  /// Why the last action on the chat failed, if it did.
  ChatActionFailureProvider._({
    required ChatActionFailureFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatActionFailureProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatActionFailureHash();

  @override
  String toString() {
    return r'chatActionFailureProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatFailure?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatFailure? create(Ref ref) {
    final argument = this.argument as String;
    return chatActionFailure(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatFailure? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatFailure?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatActionFailureProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatActionFailureHash() => r'be5f87f925237703faff74efa7e40e9a062f749b';

/// Why the last action on the chat failed, if it did.

final class ChatActionFailureFamily extends $Family
    with $FunctionalFamilyOverride<ChatFailure?, String> {
  ChatActionFailureFamily._()
    : super(
        retry: null,
        name: r'chatActionFailureProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Why the last action on the chat failed, if it did.

  ChatActionFailureProvider call(String topic) =>
      ChatActionFailureProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatActionFailureProvider';
}

/// How the user can get rid of the chat; null while the list lacks it.

@ProviderFor(chatExit)
final chatExitProvider = ChatExitFamily._();

/// How the user can get rid of the chat; null while the list lacks it.

final class ChatExitProvider
    extends $FunctionalProvider<ChatExit?, ChatExit?, ChatExit?>
    with $Provider<ChatExit?> {
  /// How the user can get rid of the chat; null while the list lacks it.
  ChatExitProvider._({
    required ChatExitFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatExitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatExitHash();

  @override
  String toString() {
    return r'chatExitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatExit?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatExit? create(Ref ref) {
    final argument = this.argument as String;
    return chatExit(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatExit? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatExit?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatExitProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatExitHash() => r'85d7e7bcb8c7605d7142d5d6a8ed0a06517cce1f';

/// How the user can get rid of the chat; null while the list lacks it.

final class ChatExitFamily extends $Family
    with $FunctionalFamilyOverride<ChatExit?, String> {
  ChatExitFamily._()
    : super(
        retry: null,
        name: r'chatExitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How the user can get rid of the chat; null while the list lacks it.

  ChatExitProvider call(String topic) =>
      ChatExitProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatExitProvider';
}

/// The chat's members as its info screen lists them, by user ID.

@ProviderFor(chatMemberIds)
final chatMemberIdsProvider = ChatMemberIdsFamily._();

/// The chat's members as its info screen lists them, by user ID.

final class ChatMemberIdsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// The chat's members as its info screen lists them, by user ID.
  ChatMemberIdsProvider._({
    required ChatMemberIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatMemberIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMemberIdsHash();

  @override
  String toString() {
    return r'chatMemberIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    final argument = this.argument as String;
    return chatMemberIds(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMemberIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMemberIdsHash() => r'4f39eba30eaca4f0f5e4b03bc5884e0b11962e8b';

/// The chat's members as its info screen lists them, by user ID.

final class ChatMemberIdsFamily extends $Family
    with $FunctionalFamilyOverride<List<String>, String> {
  ChatMemberIdsFamily._()
    : super(
        retry: null,
        name: r'chatMemberIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The chat's members as its info screen lists them, by user ID.

  ChatMemberIdsProvider call(String topic) =>
      ChatMemberIdsProvider._(argument: topic, from: this);

  @override
  String toString() => r'chatMemberIdsProvider';
}

/// One member of the chat; null once they left.

@ProviderFor(chatMember)
final chatMemberProvider = ChatMemberFamily._();

/// One member of the chat; null once they left.

final class ChatMemberProvider
    extends $FunctionalProvider<ChatMember?, ChatMember?, ChatMember?>
    with $Provider<ChatMember?> {
  /// One member of the chat; null once they left.
  ChatMemberProvider._({
    required ChatMemberFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'chatMemberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMemberHash();

  @override
  String toString() {
    return r'chatMemberProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<ChatMember?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatMember? create(Ref ref) {
    final argument = this.argument as (String, String);
    return chatMember(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatMember? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatMember?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMemberHash() => r'01a5c6610f98fb712238f7bc68a171ac00d1221c';

/// One member of the chat; null once they left.

final class ChatMemberFamily extends $Family
    with $FunctionalFamilyOverride<ChatMember?, (String, String)> {
  ChatMemberFamily._()
    : super(
        retry: null,
        name: r'chatMemberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One member of the chat; null once they left.

  ChatMemberProvider call(String topic, String userId) =>
      ChatMemberProvider._(argument: (topic, userId), from: this);

  @override
  String toString() => r'chatMemberProvider';
}

/// Whether the user may remove [userId] from the group: they manage its
/// members, and it is neither the owner nor themselves.

@ProviderFor(memberRemovable)
final memberRemovableProvider = MemberRemovableFamily._();

/// Whether the user may remove [userId] from the group: they manage its
/// members, and it is neither the owner nor themselves.

final class MemberRemovableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the user may remove [userId] from the group: they manage its
  /// members, and it is neither the owner nor themselves.
  MemberRemovableProvider._({
    required MemberRemovableFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'memberRemovableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberRemovableHash();

  @override
  String toString() {
    return r'memberRemovableProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as (String, String);
    return memberRemovable(ref, argument.$1, argument.$2);
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
    return other is MemberRemovableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberRemovableHash() => r'fe37985c035e43aeaa0ddd825a9b94c355f44f59';

/// Whether the user may remove [userId] from the group: they manage its
/// members, and it is neither the owner nor themselves.

final class MemberRemovableFamily extends $Family
    with $FunctionalFamilyOverride<bool, (String, String)> {
  MemberRemovableFamily._()
    : super(
        retry: null,
        name: r'memberRemovableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the user may remove [userId] from the group: they manage its
  /// members, and it is neither the owner nor themselves.

  MemberRemovableProvider call(String topic, String userId) =>
      MemberRemovableProvider._(argument: (topic, userId), from: this);

  @override
  String toString() => r'memberRemovableProvider';
}
