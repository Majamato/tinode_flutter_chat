// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sending in one chat: loading while a message goes into the outbox, an
/// error when that failed. Only the send button watches it.
///
/// The outbox sends it when the link allows; the chat shows it meanwhile,
/// and marks it failed if the server refuses it.

@ProviderFor(SendController)
final sendControllerProvider = SendControllerFamily._();

/// Sending in one chat: loading while a message goes into the outbox, an
/// error when that failed. Only the send button watches it.
///
/// The outbox sends it when the link allows; the chat shows it meanwhile,
/// and marks it failed if the server refuses it.
final class SendControllerProvider
    extends $NotifierProvider<SendController, AsyncValue<void>> {
  /// Sending in one chat: loading while a message goes into the outbox, an
  /// error when that failed. Only the send button watches it.
  ///
  /// The outbox sends it when the link allows; the chat shows it meanwhile,
  /// and marks it failed if the server refuses it.
  SendControllerProvider._({
    required SendControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sendControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sendControllerHash();

  @override
  String toString() {
    return r'sendControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SendController create() => SendController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SendControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sendControllerHash() => r'2bd2935ce481184782c420de6344b93ef4719bd7';

/// Sending in one chat: loading while a message goes into the outbox, an
/// error when that failed. Only the send button watches it.
///
/// The outbox sends it when the link allows; the chat shows it meanwhile,
/// and marks it failed if the server refuses it.

final class SendControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SendController,
          AsyncValue<void>,
          AsyncValue<void>,
          AsyncValue<void>,
          String
        > {
  SendControllerFamily._()
    : super(
        retry: null,
        name: r'sendControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sending in one chat: loading while a message goes into the outbox, an
  /// error when that failed. Only the send button watches it.
  ///
  /// The outbox sends it when the link allows; the chat shows it meanwhile,
  /// and marks it failed if the server refuses it.

  SendControllerProvider call(String topic) =>
      SendControllerProvider._(argument: topic, from: this);

  @override
  String toString() => r'sendControllerProvider';
}

/// Sending in one chat: loading while a message goes into the outbox, an
/// error when that failed. Only the send button watches it.
///
/// The outbox sends it when the link allows; the chat shows it meanwhile,
/// and marks it failed if the server refuses it.

abstract class _$SendController extends $Notifier<AsyncValue<void>> {
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
