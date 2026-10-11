// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requested_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A chat the host asked to open, e.g. from a tapped notification, until
/// the chat navigator opens it. It waits while nobody is logged in.

@ProviderFor(RequestedChatController)
final requestedChatControllerProvider = RequestedChatControllerProvider._();

/// A chat the host asked to open, e.g. from a tapped notification, until
/// the chat navigator opens it. It waits while nobody is logged in.
final class RequestedChatControllerProvider
    extends $NotifierProvider<RequestedChatController, String?> {
  /// A chat the host asked to open, e.g. from a tapped notification, until
  /// the chat navigator opens it. It waits while nobody is logged in.
  RequestedChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestedChatControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestedChatControllerHash();

  @$internal
  @override
  RequestedChatController create() => RequestedChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$requestedChatControllerHash() =>
    r'6104abe64f046755901ac59db7ff4b2fee2772e4';

/// A chat the host asked to open, e.g. from a tapped notification, until
/// the chat navigator opens it. It waits while nobody is logged in.

abstract class _$RequestedChatController extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
