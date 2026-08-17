import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../theme/colors.dart';

class VirtualMouseController extends ChangeNotifier {
  Offset _position = const Offset(200, 200);
  Offset get position => _position;
  bool _isVisible = true;
  bool get isVisible => _isVisible;
  bool _isPressed = false;
  bool get isPressed => _isPressed;

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
}

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
  Offset? _dragStart;
  Offset? _mouseStart;

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

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.touch) {
          _dragStart = event.position;
          _mouseStart = widget.controller.position;
          widget.controller.setPressed(true);
          // Simulate click at mouse position
          _dispatchClick(event.position, true);
        }
      },
      onPointerMove: (event) {
        if (event.kind == PointerDeviceKind.touch && _dragStart != null && _mouseStart != null) {
          final delta = event.position - _dragStart!;
          widget.controller.setPosition(_mouseStart! + delta);
        }
      },
      onPointerUp: (event) {
        if (event.kind == PointerDeviceKind.touch) {
          widget.controller.setPressed(false);
          _dispatchClick(event.position, false);
          _dragStart = null;
          _mouseStart = null;
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (widget.controller.isVisible)
            Positioned(
              left: widget.controller.position.dx,
              top: widget.controller.position.dy,
              child: IgnorePointer(
                child: _MouseCursor(pressed: widget.controller.isPressed),
              ),
            ),
        ],
      ),
    );
  }

  void _dispatchClick(Offset touchPos, bool down) {
    // Convert touch to mouse position and dispatch
    final mousePos = widget.controller.position;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      // The touch position is already global, we use mouse position for hit testing
      // This is a simplified approach - in practice we'd need custom hit testing
    }
  }
}

class _MouseCursor extends StatelessWidget {
  final bool pressed;
  const _MouseCursor({required this.pressed});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-2, -2),
      child: CustomPaint(
        size: const Size(24, 24),
        painter: _MouseCursorPainter(pressed: pressed),
      ),
    );
  }
}

class _MouseCursorPainter extends CustomPainter {
  final bool pressed;
  _MouseCursorPainter({required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 20)
      ..lineTo(6, 15)
      ..lineTo(10, 22)
      ..lineTo(13, 21)
      ..lineTo(9, 14)
      ..lineTo(16, 14)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    if (pressed) {
      final pressPaint = Paint()..color = AppColors.primary.withOpacity(0.3);
      canvas.drawCircle(const Offset(6, 10), 12, pressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MouseCursorPainter oldDelegate) => oldDelegate.pressed != pressed;
}
