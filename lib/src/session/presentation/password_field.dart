import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// A password field with an eye that shows or hides what was typed.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    required this.autofillHints,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _hidden = true;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _hidden ? strings.showPassword : strings.hidePassword,
          isSelected: !_hidden,
          icon: const Icon(Icons.visibility_outlined),
          selectedIcon: const Icon(Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
      autofillHints: widget.autofillHints,
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
    );
  }
}
