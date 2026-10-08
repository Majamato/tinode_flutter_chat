// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A search for people and groups as the user types: it waits for the
/// input to settle, asks the server and drops answers to older input. The
/// user's own account is left out.
///
/// Searching needs the server: offline it fails, and a failed search runs
/// again once the link is back.

@ProviderFor(FindController)
final findControllerProvider = FindControllerFamily._();

/// A search for people and groups as the user types: it waits for the
/// input to settle, asks the server and drops answers to older input. The
/// user's own account is left out.
///
/// Searching needs the server: offline it fails, and a failed search runs
/// again once the link is back.
final class FindControllerProvider
    extends $NotifierProvider<FindController, FindState> {
  /// A search for people and groups as the user types: it waits for the
  /// input to settle, asks the server and drops answers to older input. The
  /// user's own account is left out.
  ///
  /// Searching needs the server: offline it fails, and a failed search runs
  /// again once the link is back.
  FindControllerProvider._({
    required FindControllerFamily super.from,
    required FindScope super.argument,
  }) : super(
         retry: null,
         name: r'findControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$findControllerHash();

  @override
  String toString() {
    return r'findControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FindController create() => FindController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FindState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FindState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FindControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$findControllerHash() => r'a14cd1123e612796d4280898af2b9f72d7a8b803';

/// A search for people and groups as the user types: it waits for the
/// input to settle, asks the server and drops answers to older input. The
/// user's own account is left out.
///
/// Searching needs the server: offline it fails, and a failed search runs
/// again once the link is back.

final class FindControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FindController,
          FindState,
          FindState,
          FindState,
          FindScope
        > {
  FindControllerFamily._()
    : super(
        retry: null,
        name: r'findControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A search for people and groups as the user types: it waits for the
  /// input to settle, asks the server and drops answers to older input. The
  /// user's own account is left out.
  ///
  /// Searching needs the server: offline it fails, and a failed search runs
  /// again once the link is back.

  FindControllerProvider call(FindScope scope) =>
      FindControllerProvider._(argument: scope, from: this);

  @override
  String toString() => r'findControllerProvider';
}

/// A search for people and groups as the user types: it waits for the
/// input to settle, asks the server and drops answers to older input. The
/// user's own account is left out.
///
/// Searching needs the server: offline it fails, and a failed search runs
/// again once the link is back.

abstract class _$FindController extends $Notifier<FindState> {
  late final _$args = ref.$arg as FindScope;
  FindScope get scope => _$args;

  FindState build(FindScope scope);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FindState, FindState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FindState, FindState>,
              FindState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
