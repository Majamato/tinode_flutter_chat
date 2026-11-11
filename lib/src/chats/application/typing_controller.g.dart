// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Typing in one open chat, both ways: [Typing] for the members typing now,
/// and [typed] for the user's own key presses.
///
/// A member stops typing after [typingTimeout] without a key press, or when
/// their message arrives.

@ProviderFor(TypingController)
final typingControllerProvider = TypingControllerFamily._();

/// Typing in one open chat, both ways: [Typing] for the members typing now,
/// and [typed] for the user's own key presses.
///
/// A member stops typing after [typingTimeout] without a key press, or when
/// their message arrives.
final class TypingControllerProvider
    extends $NotifierProvider<TypingController, Typing> {
  /// Typing in one open chat, both ways: [Typing] for the members typing now,
  /// and [typed] for the user's own key presses.
  ///
  /// A member stops typing after [typingTimeout] without a key press, or when
  /// their message arrives.
  TypingControllerProvider._({
    required TypingControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'typingControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$typingControllerHash();

  @override
  String toString() {
    return r'typingControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TypingController create() => TypingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Typing value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Typing>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TypingControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$typingControllerHash() => r'3ce711e56b23854d56fad64aadecb376a6a000c4';

/// Typing in one open chat, both ways: [Typing] for the members typing now,
/// and [typed] for the user's own key presses.
///
/// A member stops typing after [typingTimeout] without a key press, or when
/// their message arrives.

final class TypingControllerFamily extends $Family
    with
        $ClassFamilyOverride<TypingController, Typing, Typing, Typing, String> {
  TypingControllerFamily._()
    : super(
        retry: null,
        name: r'typingControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Typing in one open chat, both ways: [Typing] for the members typing now,
  /// and [typed] for the user's own key presses.
  ///
  /// A member stops typing after [typingTimeout] without a key press, or when
  /// their message arrives.

  TypingControllerProvider call(String topic) =>
      TypingControllerProvider._(argument: topic, from: this);

  @override
  String toString() => r'typingControllerProvider';
}

/// Typing in one open chat, both ways: [Typing] for the members typing now,
/// and [typed] for the user's own key presses.
///
/// A member stops typing after [typingTimeout] without a key press, or when
/// their message arrives.

abstract class _$TypingController extends $Notifier<Typing> {
  late final _$args = ref.$arg as String;
  String get topic => _$args;

  Typing build(String topic);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Typing, Typing>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Typing, Typing>,
              Typing,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Who is typing in [topic], by name. In a direct chat the title already
/// names the peer.

@ProviderFor(typingMembers)
final typingMembersProvider = TypingMembersFamily._();

/// Who is typing in [topic], by name. In a direct chat the title already
/// names the peer.

final class TypingMembersProvider
    extends $FunctionalProvider<TypingMembers, TypingMembers, TypingMembers>
    with $Provider<TypingMembers> {
  /// Who is typing in [topic], by name. In a direct chat the title already
  /// names the peer.
  TypingMembersProvider._({
    required TypingMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'typingMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$typingMembersHash();

  @override
  String toString() {
    return r'typingMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TypingMembers> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TypingMembers create(Ref ref) {
    final argument = this.argument as String;
    return typingMembers(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TypingMembers value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TypingMembers>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TypingMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$typingMembersHash() => r'6c76ae52f8eb5bd1e4e0ceeaa2058e36be873050';

/// Who is typing in [topic], by name. In a direct chat the title already
/// names the peer.

final class TypingMembersFamily extends $Family
    with $FunctionalFamilyOverride<TypingMembers, String> {
  TypingMembersFamily._()
    : super(
        retry: null,
        name: r'typingMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who is typing in [topic], by name. In a direct chat the title already
  /// names the peer.

  TypingMembersProvider call(String topic) =>
      TypingMembersProvider._(argument: topic, from: this);

  @override
  String toString() => r'typingMembersProvider';
}
