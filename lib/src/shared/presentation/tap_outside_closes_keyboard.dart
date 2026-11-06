import 'package:flutter/widgets.dart';

/// Closes the keyboard on any touch outside the focused text field below
/// [child], where Flutter leaves it open on phones. The touch still lands
/// on what it hit. Also on a touch that starts a scroll: the event comes
/// as the finger lands. A widget that belongs to the field, like the
/// composer's buttons, goes in a `TextFieldTapRegion`. Watches nothing.
class TapOutsideClosesKeyboard extends StatelessWidget {
  const TapOutsideClosesKeyboard({required this.child, super.key});

  static final _actions = <Type, Action<Intent>>{
    EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
      onInvoke: (intent) {
        intent.focusNode.unfocus();
        return null;
      },
    ),
  };

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Actions(actions: _actions, child: child);
}
