import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Shown while the session connects (and logs in with known credentials).
class ConnectingView extends StatelessWidget {
  const ConnectingView({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(strings.connecting),
          ],
        ),
      ),
    );
  }
}
