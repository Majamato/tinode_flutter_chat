import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_bar.dart';

/// A screen's frosted top bar: [title] centred, with [leading] at the
/// start, under the status bar. Watches nothing.
class FrostedHeader extends StatelessWidget {
  const FrostedHeader({required this.title, this.leading, super.key});

  static const _height = 48.0;

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return FrostedBar(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
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
