import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scales artwork in both layout and paint so the surrounding editor handles
/// can be positioned against its visible bounds at any zoom level.
class ScaledOverlay extends SingleChildRenderObjectWidget {
  const ScaledOverlay({super.key, required this.scale, required Widget child})
      : super(child: child);

  final double scale;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderScaledOverlay(scale);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
    (renderObject as _RenderScaledOverlay).scale = scale;
  }
}

class _RenderScaledOverlay extends RenderProxyBox {
  _RenderScaledOverlay(this._scale);

  double _scale;
  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
    markNeedsLayout();
  }

  Matrix4 get _transform => Matrix4.diagonal3Values(_scale, _scale, 1);

  @override
  void performLayout() {
    child!.layout(constraints / _scale, parentUsesSize: true);
    size = constraints.constrain(child!.size * _scale);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(child!.getDryLayout(constraints / _scale) * _scale);

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
