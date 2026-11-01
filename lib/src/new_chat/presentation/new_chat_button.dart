import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The chat list's floating button that opens the search for people to
/// chat with. It pops in once the list has started to show; with Reduce
/// motion it is simply there. Watches nothing.
class NewChatButton extends StatefulWidget {
  const NewChatButton({super.key});

  /// When it starts to pop in, after the screen opens.
  static const delay = Duration(milliseconds: 350);

  static const _pop = Duration(milliseconds: 500);

  @override
  State<NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<NewChatButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: NewChatButton.delay + NewChatButton._pop,
  );
  CurvedAnimation? _scale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final start =
        NewChatButton.delay.inMicroseconds /
        _controller.duration!.inMicroseconds;
    _scale?.dispose();
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: TinodeChatTheme.of(context).springCurve),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _scale?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale!,
      child: FloatingActionButton(
        tooltip: TinodeChatStrings.of(context).newMessage,
        onPressed: () => FindPeopleScreen.open(context),
        child: Icon(TinodeChatIcons.of(context).newChat),
      ),
    );
  }
}
