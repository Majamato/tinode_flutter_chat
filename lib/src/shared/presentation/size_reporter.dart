import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays out its [child] as is and puts the child's height in [height]
/// after each frame it changes, e.g. so a list can pad itself under a bar
/// that floats over it. Only for a bar whose height depends on its content
/// (the composer); a header goes in `Scaffold.appBar`, which puts the body
/// below it.
class SizeReporter extends SingleChildRenderObjectWidget {
  const SizeReporter({required this.height, super.child, super.key});

  final ValueNotifier<double> height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(height);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSizeReporter).height = height;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.height);

  ValueNotifier<double> height;

  @override
  void performLayout() {
    super.performLayout();
    final measured = size.height;
    if (measured != height.value) {
      // Listeners may rebuild, which can't happen during layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        height.value = measured;
      });
    }
  }
}
