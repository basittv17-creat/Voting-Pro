import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scales artwork in both layout and paint so the surrounding editor handles
/// can be positioned against its visible bounds at any zoom level.
class ScaledOverlay extends SingleChildRenderObjectWidget {
  const ScaledOverlay(
      {super.key,
      required this.scale,
      this.fitHeight = false,
      required Widget child})
      : super(child: child);

  final double scale;
  final bool fitHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderScaledOverlay(scale, fitHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
    (renderObject as _RenderScaledOverlay)
      ..scale = scale
      ..fitHeight = fitHeight;
  }
}

class _RenderScaledOverlay extends RenderProxyBox {
  _RenderScaledOverlay(this._scale, this._fitHeight);

  bool _fitHeight;
  double _paintScale = 1;

  set fitHeight(bool value) {
    if (value == _fitHeight) return;
    _fitHeight = value;
    markNeedsLayout();
  }

  double _scale;
  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
    markNeedsLayout();
  }

  Matrix4 get _transform =>
      Matrix4.diagonal3Values(_paintScale, _paintScale, 1);

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    final unscaled = constraints / _scale;
    return _fitHeight
        ? unscaled.copyWith(maxHeight: double.infinity)
        : unscaled;
  }

  double _fittedScale(BoxConstraints constraints, Size childSize) =>
      _fitHeight && childSize.height > 0
          ? math.min(_scale, constraints.maxHeight / childSize.height)
          : _scale;

  @override
  void performLayout() {
    child!.layout(_childConstraints(constraints), parentUsesSize: true);
    _paintScale = _fittedScale(constraints, child!.size);
    size = constraints.constrain(child!.size * _paintScale);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childSize = child!.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(
      childSize * _fittedScale(constraints, childSize),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushTransform(needsCompositing, offset, _transform, super.paint);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintTransform(
        transform: _transform,
        position: position,
        hitTest: (result, position) =>
            super.hitTestChildren(result, position: position),
      );

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}
