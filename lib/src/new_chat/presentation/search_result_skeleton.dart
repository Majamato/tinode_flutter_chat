import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';

/// Rows shaped like [SearchResultTile]s while a search has found nothing
/// yet, some with a group's label under the name. Watches nothing.
class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  /// How much of the room each row's name takes, and whether a label
  /// follows it.
  static const _rows = [
    (0.52, false),
    (0.4, true),
    (0.64, false),
    (0.46, false),
    (0.58, true),
    (0.36, false),
    (0.5, false),
    (0.62, true),
    (0.44, false),
    (0.56, false),
    (0.48, true),
    (0.6, false),
  ];

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final (name, label) = _rows[index];
          return ListTile(
            leading: const SkeletonBone.circle(40),
            title: SkeletonBone.line(widthFactor: name, height: 14),
            subtitle: label
                ? const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SkeletonBone.line(width: 48, height: 10),
                  )
                : null,
          );
        },
      ),
    );
  }
}
