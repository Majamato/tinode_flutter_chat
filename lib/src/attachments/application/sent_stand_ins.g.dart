// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sent_stand_ins.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The stand-ins outgoing bubbles leave for their sent ones.

@ProviderFor(sentStandIns)
final sentStandInsProvider = SentStandInsProvider._();

/// The stand-ins outgoing bubbles leave for their sent ones.

final class SentStandInsProvider
    extends $FunctionalProvider<SentStandIns, SentStandIns, SentStandIns>
    with $Provider<SentStandIns> {
  /// The stand-ins outgoing bubbles leave for their sent ones.
  SentStandInsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sentStandInsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sentStandInsHash();

  @$internal
  @override
  $ProviderElement<SentStandIns> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SentStandIns create(Ref ref) {
    return sentStandIns(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SentStandIns value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SentStandIns>(value),
    );
  }
}

String _$sentStandInsHash() => r'f259a41c30dda2aac5ee3e4babb39d5d84abd210';
