import 'package:flutter/material.dart';

/// A filled button that shows a spinner in place of its [label] while
/// [busy], and can't be pressed then. A [trailingIcon] follows the label.
class ProgressButton extends StatelessWidget {
  const ProgressButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final IconData? trailingIcon;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : switch (trailingIcon) {
              null => Text(label),
              final icon => Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text(label), const SizedBox(width: 8), Icon(icon)],
              ),
            },
    );
  }
}
