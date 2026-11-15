import 'package:flutter/widgets.dart';

/// The last row of a list that has more to read: shows [child], usually a
/// skeleton row, and calls [onShown] once it is built, after that frame.
///
/// A list builds rows only in view or within its `cacheExtent` of it, so
/// this asks for the next page as the end comes near. A page that still
/// leaves it in reach puts a new one there, which asks again: a list
/// shorter than the screen keeps reading until it fills it or nothing is
/// left. [onShown] must do nothing while a page is being read. Watches
/// nothing.
class LoadMoreRow extends StatefulWidget {
  const LoadMoreRow({required this.onShown, required this.child, super.key});

  final VoidCallback onShown;

  final Widget child;

  @override
  State<LoadMoreRow> createState() => _LoadMoreRowState();
}

class _LoadMoreRowState extends State<LoadMoreRow> {
  @override
  void initState() {
    super.initState();
    // Not while the list builds: reading changes what it shows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onShown();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
