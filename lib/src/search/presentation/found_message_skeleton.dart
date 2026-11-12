import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/search/presentation/found_message_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';

/// Rows shaped like [FoundMessageTile]s: the sender, the words around the
/// match and the time. A whole screen of them while a search has found
/// nothing yet, or [rows] at the end of the list while more load. Watches
/// nothing.
class FoundMessageSkeleton extends StatelessWidget {
  const FoundMessageSkeleton({this.rows, super.key});

  /// How many rows, shrink-wrapped; null fills the screen.
  final int? rows;

  /// How much of the room each row's sender and snippet take.
  static const _shapes = [
    (0.36, 0.86),
    (0.48, 0.7),
    (0.3, 0.92),
    (0.42, 0.78),
    (0.54, 0.64),
    (0.38, 0.88),
  ];

  /// More than any screen shows.
  static const _screenful = 14;

  @override
  Widget build(BuildContext context) {
    final rows = this.rows;
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: rows != null,
        padding: rows == null ? null : EdgeInsets.zero,
        itemCount: rows ?? _screenful,
        itemBuilder: (context, index) {
          final (sender, snippet) = _shapes[index % _shapes.length];
          return ListTile(
            title: SkeletonBone.line(widthFactor: sender, height: 14),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SkeletonBone.line(widthFactor: snippet),
            ),
            trailing: const SkeletonBone.line(width: 36, height: 10),
          );
        },
      ),
    );
  }
}
