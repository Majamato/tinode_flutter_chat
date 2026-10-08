// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The call of this device: places calls, rings for incoming ones, and
/// drives the WebRTC link through [CallMedia] as the peer's call events
/// arrive.
///
/// The call's topic stays attached for the whole call, whatever screen is
/// open. Incoming calls arrive as a call message in an attached chat, or,
/// for other chats, as `pres msg` on `me`, after which an *invite check*
/// attaches the chat and reads the new message.

@ProviderFor(CallController)
final callControllerProvider = CallControllerProvider._();

/// The call of this device: places calls, rings for incoming ones, and
/// drives the WebRTC link through [CallMedia] as the peer's call events
/// arrive.
///
/// The call's topic stays attached for the whole call, whatever screen is
/// open. Incoming calls arrive as a call message in an attached chat, or,
/// for other chats, as `pres msg` on `me`, after which an *invite check*
/// attaches the chat and reads the new message.
final class CallControllerProvider
    extends $NotifierProvider<CallController, ActiveCall?> {
  /// The call of this device: places calls, rings for incoming ones, and
  /// drives the WebRTC link through [CallMedia] as the peer's call events
  /// arrive.
  ///
  /// The call's topic stays attached for the whole call, whatever screen is
  /// open. Incoming calls arrive as a call message in an attached chat, or,
  /// for other chats, as `pres msg` on `me`, after which an *invite check*
  /// attaches the chat and reads the new message.
  CallControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'callControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$callControllerHash();

  @$internal
  @override
  CallController create() => CallController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveCall? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveCall?>(value),
    );
  }
}

String _$callControllerHash() => r'e407b5e2b0bc154250b755c32fb29322002b4bf1';

/// The call of this device: places calls, rings for incoming ones, and
/// drives the WebRTC link through [CallMedia] as the peer's call events
/// arrive.
///
/// The call's topic stays attached for the whole call, whatever screen is
/// open. Incoming calls arrive as a call message in an attached chat, or,
/// for other chats, as `pres msg` on `me`, after which an *invite check*
/// attaches the chat and reads the new message.

abstract class _$CallController extends $Notifier<ActiveCall?> {
  ActiveCall? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActiveCall?, ActiveCall?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveCall?, ActiveCall?>,
              ActiveCall?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether the user can call the peer of [topic]: a 1:1 chat they may
/// write to, on a server that takes calls.

@ProviderFor(callsAvailable)
final callsAvailableProvider = CallsAvailableFamily._();

/// Whether the user can call the peer of [topic]: a 1:1 chat they may
/// write to, on a server that takes calls.

final class CallsAvailableProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the user can call the peer of [topic]: a 1:1 chat they may
  /// write to, on a server that takes calls.
  CallsAvailableProvider._({
    required CallsAvailableFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'callsAvailableProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$callsAvailableHash();

  @override
  String toString() {
    return r'callsAvailableProvider'
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
    return callsAvailable(ref, argument);
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
    return other is CallsAvailableProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$callsAvailableHash() => r'3217170eb4cc0f1fcad9fd618d3ec7efa12dbcb4';

/// Whether the user can call the peer of [topic]: a 1:1 chat they may
/// write to, on a server that takes calls.

final class CallsAvailableFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  CallsAvailableFamily._()
    : super(
        retry: null,
        name: r'callsAvailableProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the user can call the peer of [topic]: a 1:1 chat they may
  /// write to, on a server that takes calls.

  CallsAvailableProvider call(String topic) =>
      CallsAvailableProvider._(argument: topic, from: this);

  @override
  String toString() => r'callsAvailableProvider';
}
