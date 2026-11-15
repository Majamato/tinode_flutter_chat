import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_search/call_search_input.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_search/call_search_results.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// The call search: the calls of the whole call log, voice and video,
/// filtered by the chat's name as the user types, without the server. Its
/// rows are drawn as the calls history's. Watches nothing itself.
class CallSearchScreen extends StatelessWidget {
  const CallSearchScreen({super.key});

  /// Pushes the call search over the calls history.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CallSearchScreen()));

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      screen: TinodeCallSearchScreen(),
      appBar: TinodeAppBar(
        centerTitle: false,
        titleOnGlass: true,
        leading: TinodeBackButton(),
        title: GlassField(child: CallSearchInput()),
      ),
      body: SafeArea(bottom: false, child: CallSearchResults()),
    );
  }
}
