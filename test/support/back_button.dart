import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

/// The back button on screen.
Finder backButton() => find.byType(TinodeBackButton);

/// Any text on the back button on screen: none for the chevron alone.
Finder backText() =>
    find.descendant(of: backButton(), matching: find.byType(Text));

/// [label] on the back button on screen.
Finder backLabelled(String label) =>
    find.descendant(of: backButton(), matching: find.text(label));
