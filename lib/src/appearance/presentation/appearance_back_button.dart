import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// "‹ [label]" in the link colour on a glass pill: back to the screen
/// named [label]. Watches nothing.
class AppearanceBackButton extends StatelessWidget {
  const AppearanceBackButton({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = TinodeChatTheme.of(context).linkColor;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      excludeSemantics: true,
      child: GlassSurface(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 6, end: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TinodeChatIcons.of(context).back,
                      size: 24,
                      color: color,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
