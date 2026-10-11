// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'found_sender.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Who sent a message found in [topic], from the user ID [from]. A group
/// member's name comes from the chat's members, kept on the device.

@ProviderFor(foundSender)
final foundSenderProvider = FoundSenderFamily._();

/// Who sent a message found in [topic], from the user ID [from]. A group
/// member's name comes from the chat's members, kept on the device.

final class FoundSenderProvider
    extends $FunctionalProvider<FoundSender, FoundSender, FoundSender>
    with $Provider<FoundSender> {
  /// Who sent a message found in [topic], from the user ID [from]. A group
  /// member's name comes from the chat's members, kept on the device.
  FoundSenderProvider._({
    required FoundSenderFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'foundSenderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foundSenderHash();

  @override
  String toString() {
    return r'foundSenderProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<FoundSender> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FoundSender create(Ref ref) {
    final argument = this.argument as (String, String?);
    return foundSender(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoundSender value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoundSender>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoundSenderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foundSenderHash() => r'aea6d699dc3336cb5b0904ea69ca358f80c10ef1';

/// Who sent a message found in [topic], from the user ID [from]. A group
/// member's name comes from the chat's members, kept on the device.

final class FoundSenderFamily extends $Family
    with $FunctionalFamilyOverride<FoundSender, (String, String?)> {
  FoundSenderFamily._()
    : super(
        retry: null,
        name: r'foundSenderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who sent a message found in [topic], from the user ID [from]. A group
  /// member's name comes from the chat's members, kept on the device.

  FoundSenderProvider call(String topic, String? from) =>
      FoundSenderProvider._(argument: (topic, from), from: this);

  @override
  String toString() => r'foundSenderProvider';
}
