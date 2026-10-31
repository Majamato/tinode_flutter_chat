import 'package:flutter/painting.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

/// The package's neutral palette, as a host offers it.
const slate = TinodeAppearancePalette(
  id: 'slate',
  label: 'Slate',
  colors: TinodeChatPalette.neutral,
);

/// A second palette to pick.
const plum = TinodeAppearancePalette(
  id: 'plum',
  label: 'Plum',
  colors: TinodeChatPalette(
    primary: Color(0xFF5B1A8C),
    night: Color(0xFF7A2BB8),
    bright: Color(0xFFB57BEB),
    accent: Color(0xFFFF8A3D),
    soft: Color(0xFFF1E5FA),
    ink: Color(0xFF4A1473),
    onDark: Color(0xFFD9B8F5),
    deep: Color(0xFF14061F),
    scene: Color(0xFF221033),
  ),
);
