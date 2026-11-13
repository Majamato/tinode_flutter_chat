import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/search_result_tile.dart';

/// The results of a search, best first, with a progress bar while newer
/// ones are on their way. Watches nothing.
class SearchResultList extends StatelessWidget {
  const SearchResultList({
    required this.results,
    required this.searching,
    required this.onSelected,
    super.key,
  });

  final List<SearchResult> results;
  final bool searching;
  final ValueChanged<SearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (searching) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return SearchResultTile(
                key: ValueKey(result.topic),
                result: result,
                onTap: () => onSelected(result),
              );
            },
          ),
        ),
      ],
    );
  }
}
