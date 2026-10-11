import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/search/domain/message_snippet.dart';

/// The words around what message search matched, the matches in bold.
class MessageSnippetText extends StatelessWidget {
  const MessageSnippetText({required this.snippet, super.key});

  final MessageSnippet snippet;

  @override
  Widget build(BuildContext context) {
    final match = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
    return Text.rich(
      TextSpan(
        children: [
          for (final part in snippet.parts)
            TextSpan(text: part.text, style: part.match ? match : null),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
