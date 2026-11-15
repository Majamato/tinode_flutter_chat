import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_tile.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';

/// Rows shaped like [CallHistoryTile]s: as many as the screen shows, under
/// the app bar (the top padding of [MediaQuery]), until the call log was
/// read, or [rows] at the end of a list while more load. Watches nothing.
class CallHistorySkeleton extends StatelessWidget {
  const CallHistorySkeleton({this.rows, super.key});

  /// How many rows, shrink-wrapped; null fills the screen.
  final int? rows;

  /// More than any screen shows; the list builds only those in view.
  static const _screenful = 24;

  /// How much of the room each row's name and status take.
  static const _names = [0.44, 0.6, 0.36, 0.52, 0.68];
  static const _statuses = [0.62, 0.5, 0.74, 0.56];

  @override
  Widget build(BuildContext context) {
    final rows = this.rows;
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: rows != null,
        padding: rows == null ? null : EdgeInsets.zero,
        itemExtent: CallHistoryTile.height,
        itemCount: rows ?? _screenful,
        itemBuilder: (context, index) => _Row(
          name: _names[index % _names.length],
          status: _statuses[index % _statuses.length],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.name, required this.status});

  final double name;
  final double status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: Row(
        children: [
          const SkeletonBone.circle(48),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          SkeletonBone.line(widthFactor: name, height: 14),
                          Row(
                            spacing: 4,
                            children: [
                              const SkeletonBone.circle(ChatIconSize.small),
                              Expanded(
                                child: SkeletonBone.line(widthFactor: status),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SkeletonBone.line(width: 36, height: 10),
                    // Where the chat button's icon sits.
                    const SizedBox(width: 12),
                    const SkeletonBone.circle(ChatIconSize.standard),
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
