import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A message's `text` with its `footer` (time and ticks) at the end of the
/// last line when they fit there, else on a line of their own, aligned to
/// the end.
class BubbleTextLayout extends MultiChildRenderObjectWidget {
  BubbleTextLayout({required Widget text, required Widget footer, super.key})
    : super(children: [text, footer]);

  @override
  RenderBubbleTextLayout createRenderObject(BuildContext context) =>
      RenderBubbleTextLayout(textDirection: Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBubbleTextLayout renderObject,
  ) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class _LayoutParentData extends ContainerBoxParentData<RenderBox> {}

/// Lays out [BubbleTextLayout]: the text first, then the footer after its
/// last line or below it.
class RenderBubbleTextLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _LayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _LayoutParentData> {
  RenderBubbleTextLayout({required TextDirection textDirection})
    : _textDirection = textDirection;

  /// Space between the last word and the footer.
  static const gap = 8.0;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value != _textDirection) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  RenderBox get _text => firstChild!;
  RenderBox get _footer => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LayoutParentData) {
      child.parentData = _LayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => max(
    _text.getMinIntrinsicWidth(height),
    _footer.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _text.getMaxIntrinsicWidth(height) +
      gap +
      _footer.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _text.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _text.getMaxIntrinsicHeight(width) + _footer.getMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      debugCannotComputeDryLayout(
        reason: 'Where the footer goes depends on where the text wraps.',
      ),
      'BubbleTextLayout has no dry layout',
    );
    return Size.zero;
  }

  @override
  void performLayout() {
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    _text.layout(loose, parentUsesSize: true);
    _footer.layout(loose, parentUsesSize: true);
    final text = _text.size;
    final footer = _footer.size;

    final lineEnd = _lastLineEnd();
    final inline = lineEnd + gap + footer.width <= constraints.maxWidth;
    final width = inline
        ? max(text.width, lineEnd + gap + footer.width)
        : max(text.width, footer.width);
    final height = inline
        ? max(text.height, footer.height)
        : text.height + footer.height;
    size = constraints.constrain(Size(width, height));

    final ltr = _textDirection == TextDirection.ltr;
    (_text.parentData! as _LayoutParentData).offset = Offset(
      ltr ? 0 : size.width - text.width,
      0,
    );
    (_footer.parentData! as _LayoutParentData).offset = Offset(
      ltr ? size.width - footer.width : 0,
      size.height - footer.height,
    );
  }

  /// How far the text's last line reaches from its start edge; the whole
  /// width when the text isn't a plain paragraph.
  double _lastLineEnd() {
    final paragraph = _paragraphOf(_text);
    if (paragraph == null) {
      return _text.size.width;
    }
    final length = paragraph.text.toPlainText().length;
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: length),
      Rect.zero,
    );
    return _textDirection == TextDirection.ltr
        ? caret.dx
        : paragraph.size.width - caret.dx;
  }

  static RenderParagraph? _paragraphOf(RenderObject box) => switch (box) {
    final RenderParagraph paragraph => paragraph,
    RenderObjectWithChildMixin<RenderBox>(:final child?) => _paragraphOf(child),
    _ => null,
  };

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
