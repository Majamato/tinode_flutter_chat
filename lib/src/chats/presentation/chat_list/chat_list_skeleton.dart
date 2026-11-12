import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';

/// Rows shaped like [ChatListTile]s while the chat list loads, under the
/// app bar (the top padding of [MediaQuery]) and as many as the screen
/// shows. Watches nothing.
class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  /// More than any screen shows; the list builds only those in view.
  static const _rows = 24;

  /// How much of the room each row's name and preview take, so the rows
  /// don't look stamped.
  static const _names = [0.46, 0.62, 0.38, 0.54, 0.7, 0.42];
  static const _previews = [0.82, 0.64, 0.9, 0.72, 0.56, 0.86, 0.68];

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemExtent: ChatListTile.height,
        itemCount: _rows,
        itemBuilder: (context, index) => _Row(
          name: _names[index % _names.length],
          preview: _previews[index % _previews.length],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.name, required this.preview});

  final double name;
  final double preview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: Row(
        children: [
          const SkeletonBone.circle(56),
          const SizedBox(width: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonBone.line(
                            widthFactor: name,
                            height: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SkeletonBone.line(width: 36, height: 10),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SkeletonBone.line(widthFactor: preview),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
