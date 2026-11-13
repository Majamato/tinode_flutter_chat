import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';

/// The text field of a search; each change goes to the [scope]'s search.
/// Watches nothing.
class FindField extends ConsumerStatefulWidget {
  const FindField({
    required this.scope,
    required this.hint,
    this.autofocus = true,
    this.onChanged,
    super.key,
  });

  final FindScope scope;
  final String hint;
  final bool autofocus;

  /// Also told each change, after the search.
  final ValueChanged<String>? onChanged;

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

  void _changed(String text) {
    ref.read(findControllerProvider(widget.scope).notifier).search(text);
    widget.onChanged?.call(text);
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
        prefixIcon: Icon(TinodeChatIcons.of(context).search),
        border: InputBorder.none,
      ),
      onChanged: _changed,
    );
  }
}
