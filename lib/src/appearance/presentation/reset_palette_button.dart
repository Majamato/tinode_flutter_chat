import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/presentation/appearance_scope.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// "Reset to" and the default palette's name, in the link colour: back to
/// the host's default palette, the theme left as it is. Disabled while it
/// is in use. Watches the appearance.
class ResetPaletteButton extends StatelessWidget {
  const ResetPaletteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.maybeOf(context);
    if (appearance == null) {
      return const SizedBox.shrink();
    }
    final fallback = appearance.defaultPalette;
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: TinodeChatTheme.of(context).linkColor,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: appearance.palette.id == fallback.id
            ? null
            : appearance.resetPalette,
        child: Text(TinodeChatStrings.of(context).resetPalette(fallback.label)),
      ),
    );
  }
}
