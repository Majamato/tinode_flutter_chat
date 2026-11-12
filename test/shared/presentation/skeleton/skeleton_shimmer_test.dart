import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() {
  Future<void> pumpShimmer(
    WidgetTester tester, {
    required bool reduceMotion,
    Widget child = const SkeletonBone.rect(width: 200, height: 20),
  }) => tester.pumpWidget(
    MaterialApp(
      theme: TinodeChatTheme.materialTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(body: SkeletonShimmer(child: child)),
    ),
  );

  testWidgets('holds still with Reduce motion', (tester) async {
    await pumpShimmer(tester, reduceMotion: true);

    expect(find.byType(ShaderMask), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('sweeps the band over the bones otherwise', (tester) async {
    await pumpShimmer(tester, reduceMotion: false);

    final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
    expect(mask.blendMode, BlendMode.srcATop);
    // It keeps ticking, a sweep after another.
    await tester.pump(SkeletonShimmer.period * 3);
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    // Turning Reduce motion on stops it.
    await pumpShimmer(tester, reduceMotion: true);
    expect(find.byType(ShaderMask), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reads "Loading…" once, not the bones', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpShimmer(
      tester,
      reduceMotion: true,
      child: const Column(
        children: [
          SkeletonBone.circle(40),
          SkeletonBone.line(width: 100),
          Text('hidden'),
        ],
      ),
    );

    expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    expect(find.bySemanticsLabel('hidden'), findsNothing);
    semantics.dispose();
  });

  testWidgets('takes no touches', (tester) async {
    var taps = 0;
    await pumpShimmer(
      tester,
      reduceMotion: true,
      child: GestureDetector(
        onTap: () => taps++,
        child: const SkeletonBone.rect(width: 200, height: 20),
      ),
    );

    await tester.tap(find.byType(SkeletonBone), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('bones take the theme colour unless given one', (tester) async {
    await pumpShimmer(
      tester,
      reduceMotion: true,
      child: const Column(
        children: [
          SkeletonBone.circle(40),
          SkeletonBone.circle(40, color: Colors.red),
        ],
      ),
    );

    final chat = TinodeChatTheme.of(tester.element(find.byType(Column)));
    final colors = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(SkeletonBone),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => (box.decoration as BoxDecoration).color);
    expect(colors, [chat.skeletonColor, Colors.red]);
  });
}
