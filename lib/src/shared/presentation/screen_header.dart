import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/header_bar.dart';

/// A screen's top bar: [title] centred, with [leading] at the start,
/// under the status bar. Watches nothing.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({required this.title, this.leading, super.key});

  static const _height = 48.0;

  /// Room between the title row and the hairline.
  static const _bottomPadding = 6.0;

  final String title;
  final Widget? leading;

  /// Below the status bar: the [Scaffold] adds that and caps the header
  /// at the sum, so this must not be less than what [build] lays out.
  @override
  Size get preferredSize => const Size.fromHeight(_height + _bottomPadding);

  @override
  Widget build(BuildContext context) {
    return HeaderBar(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, _bottomPadding),
          child: SizedBox(
            height: _height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 104),
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (leading case final leading?)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: leading,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
