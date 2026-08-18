import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../theme/colors.dart';

/// 虚拟鼠标控制器
class VirtualMouseController extends ChangeNotifier {
  Offset _position = const Offset(200, 200);
  Offset get position => _position;
  bool _isVisible = true;
  bool get isVisible => _isVisible;
  bool _isPressed = false;
  bool get isPressed => _isPressed;
  bool _isRightPressed = false;
  bool get isRightPressed => _isRightPressed;

  void setPosition(Offset pos) {
    _position = pos;
    notifyListeners();
  }

  void setVisible(bool v) {
    _isVisible = v;
    notifyListeners();
  }

  void setPressed(bool p) {
    _isPressed = p;
    notifyListeners();
  }

  void setRightPressed(bool p) {
    _isRightPressed = p;
    notifyListeners();
  }
}

/// 虚拟鼠标包装器：将触摸转换为鼠标事件，通过GestureBinding分发给下层Widget
class VirtualMouseWrapper extends StatefulWidget {
  final Widget child;
  final VirtualMouseController controller;
  final bool enabled;

  const VirtualMouseWrapper({
    super.key,
    required this.child,
    required this.controller,
    this.enabled = true,
  });

  @override
  State<VirtualMouseWrapper> createState() => _VirtualMouseWrapperState();
}

class _VirtualMouseWrapperState extends State<VirtualMouseWrapper> {
  Offset? _touchStart;
  Offset? _mouseStart;
  int? _pointerId;
  DateTime? _downTime;
  bool _isLongPress = false;
  static const int _longPressMs = 500;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  /// 将全局坐标转换为本地坐标
  Offset _globalToLocal(Offset global) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      return renderObject.globalToLocal(global);
    }
    return global;
  }

  /// 分发指针事件到GestureBinding
  void _dispatchPointerEvent(PointerEvent event) {
    GestureBinding.instance.dispatchEvent(event, HitTestResult());
  }

  /// 在鼠标位置分发按下事件
  void _dispatchDown(Offset globalPos) {
    _pointerId ??= DateTime.now().millisecondsSinceEpoch % 100000;
    final event = PointerDownEvent(
      pointer: _pointerId!,
      kind: PointerDeviceKind.mouse,
      position: globalPos,
      buttons: kPrimaryButton,
    );
    _dispatchPointerEvent(event);
  }

  /// 在鼠标位置分发移动事件
  void _dispatchMove(Offset globalPos) {
    if (_pointerId == null) return;
    final event = PointerMoveEvent(
      pointer: _pointerId!,
      kind: PointerDeviceKind.mouse,
      position: globalPos,
      buttons: kPrimaryButton,
    );
    _dispatchPointerEvent(event);
  }

  /// 在鼠标位置分发抬起事件
  void _dispatchUp(Offset globalPos) {
    if (_pointerId == null) return;
    final event = PointerUpEvent(
      pointer: _pointerId!,
      kind: PointerDeviceKind.mouse,
      position: globalPos,
      buttons: kPrimaryButton,
    );
    _dispatchPointerEvent(event);
    _pointerId = null;
  }

  /// 分发右键按下（用于长按）
  void _dispatchRightDown(Offset globalPos) {
    _pointerId ??= DateTime.now().millisecondsSinceEpoch % 100000;
    final event = PointerDownEvent(
      pointer: _pointerId!,
      kind: PointerDeviceKind.mouse,
      position: globalPos,
      buttons: kSecondaryButton,
    );
    _dispatchPointerEvent(event);
  }

  void _dispatchRightUp(Offset globalPos) {
    if (_pointerId == null) return;
    final event = PointerUpEvent(
      pointer: _pointerId!,
      kind: PointerDeviceKind.mouse,
      position: globalPos,
      buttons: kSecondaryButton,
    );
    _dispatchPointerEvent(event);
    _pointerId = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (event.kind != PointerDeviceKind.touch) return;
        _touchStart = event.position;
        _mouseStart = widget.controller.position;
        _downTime = DateTime.now();
        _isLongPress = false;
        widget.controller.setPressed(true);
        // 在鼠标当前位置分发按下事件
        _dispatchDown(widget.controller.position);
        // 检测长按
        Future.delayed(const Duration(milliseconds: _longPressMs), () {
          if (_touchStart != null && !_isLongPress && mounted) {
            _isLongPress = true;
            widget.controller.setRightPressed(true);
            _dispatchRightDown(widget.controller.position);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _dispatchRightUp(widget.controller.position);
                widget.controller.setRightPressed(false);
              }
            });
          }
        });
      },
      onPointerMove: (event) {
        if (event.kind != PointerDeviceKind.touch || _touchStart == null || _mouseStart == null) return;
        final delta = event.position - _touchStart!;
        final newPos = _mouseStart! + delta;
        widget.controller.setPosition(newPos);
        // 如果不是长按，分发移动事件实现拖动
        if (!_isLongPress) {
          _dispatchMove(newPos);
        }
      },
      onPointerUp: (event) {
        if (event.kind != PointerDeviceKind.touch) return;
        widget.controller.setPressed(false);
        if (!_isLongPress) {
          _dispatchUp(widget.controller.position);
        }
        _touchStart = null;
        _mouseStart = null;
        _downTime = null;
      },
      onPointerCancel: (event) {
        if (event.kind != PointerDeviceKind.touch) return;
        widget.controller.setPressed(false);
        if (!_isLongPress && _pointerId != null) {
          _dispatchUp(widget.controller.position);
        }
        _touchStart = null;
        _mouseStart = null;
      },
      child: Stack(
        children: [
          // AbsorbPointer阻止原始触摸事件穿透到child，
          // 但我们通过Listener在上方拦截后用GestureBinding分发模拟鼠标事件
          AbsorbPointer(
            absorbing: true,
            child: widget.child,
          ),
          // 鼠标光标
          if (widget.controller.isVisible)
            Positioned(
              left: widget.controller.position.dx - 2,
              top: widget.controller.position.dy - 2,
              child: IgnorePointer(
                child: _MouseCursor(
                  pressed: widget.controller.isPressed,
                  rightPressed: widget.controller.isRightPressed,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 鼠标光标绘制
class _MouseCursor extends StatelessWidget {
  final bool pressed;
  final bool rightPressed;
  const _MouseCursor({required this.pressed, this.rightPressed = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _MouseCursorPainter(pressed: pressed, rightPressed: rightPressed),
    );
  }
}

class _MouseCursorPainter extends CustomPainter {
  final bool pressed;
  final bool rightPressed;
  _MouseCursorPainter({required this.pressed, this.rightPressed = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 点击反馈光圈
    if (pressed) {
      final glowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(const Offset(8, 8), 16, glowPaint);
    }

    // 鼠标主体
    final fillPaint = Paint()
      ..color = rightPressed ? AppColors.accent : Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(2, 2)
      ..lineTo(2, 22)
      ..lineTo(8, 17)
      ..lineTo(12, 24)
      ..lineTo(15, 23)
      ..lineTo(11, 16)
      ..lineTo(18, 16)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // 左键高亮
    if (pressed) {
      final leftBtnPaint = Paint()..color = AppColors.primary.withOpacity(0.5);
      final leftBtnPath = Path()
        ..moveTo(2, 2)
        ..lineTo(10, 2)
        ..lineTo(10, 12)
        ..lineTo(2, 12)
        ..close();
      canvas.drawPath(leftBtnPath, leftBtnPath.getBounds() as Paint);
      canvas.drawPath(leftBtnPath, leftBtnPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MouseCursorPainter oldDelegate) =>
      oldDelegate.pressed != pressed || oldDelegate.rightPressed != rightPressed;
}
