import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The text that explains [failure] to the user.
String failureMessage(TinodeChatStrings strings, ChatFailure failure) =>
    switch (failure) {
      ChatFailure.unreachable => strings.unreachable,
      ChatFailure.connectionLost => strings.connectionLost,
      ChatFailure.badCredentials => strings.badCredentials,
      ChatFailure.timeout => strings.timeout,
      ChatFailure.rejected => strings.rejected,
      ChatFailure.unexpected => strings.unexpected,
      ChatFailure.tooLarge => strings.fileTooLarge,
    };
