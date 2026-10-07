import 'package:tinode_flutter_chat/src/calls/domain/call_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The text that explains [failure] to the user.
String callFailureMessage(TinodeChatStrings strings, CallFailure failure) =>
    switch (failure) {
      CallFailure.permissionDenied => strings.callPermissionDenied,
      CallFailure.busy => strings.callBusy,
      CallFailure.unavailable => strings.callUnavailable,
      CallFailure.connectionLost => strings.connectionLost,
      CallFailure.mediaFailed || CallFailure.unexpected => strings.callFailed,
    };
