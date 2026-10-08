import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';

/// The text field of a search; each change goes to the [scope]'s search.
/// Watches nothing.
class FindField extends ConsumerStatefulWidget {
  const FindField({
    required this.scope,
    required this.hint,
    this.autofocus = true,
    super.key,
  });

  final FindScope scope;
  final String hint;
  final bool autofocus;

  @override
  ConsumerState<FindField> createState() => _FindFieldState();
}

class _FindFieldState extends ConsumerState<FindField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        border: InputBorder.none,
      ),
      onChanged: (text) =>
          ref.read(findControllerProvider(widget.scope).notifier).search(text),
    );
  }
}
