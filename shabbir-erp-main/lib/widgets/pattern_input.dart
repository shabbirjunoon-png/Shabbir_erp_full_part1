import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PatternInput extends StatefulWidget {
  final void Function(String pattern) onComplete;
  final int gridSize;
  final Color? activeColor;

  const PatternInput({
    super.key,
    required this.onComplete,
    this.gridSize = 3,
    this.activeColor,
  });

  @override
  State<PatternInput> createState() => _PatternInputState();
}

class _PatternInputState extends State<PatternInput> {
  final List<int> _selected = [];
  Offset? _currentPoint;
  bool _complete = false;
  Size _widgetSize = Size.zero;

  static const double _hitRadius = 38.0;
  static const double _dotRadius = 12.0;
  static const double _activeDotRadius = 18.0;

  List<Offset> _getDotCenters(Size size) {
    final n = widget.gridSize;
    final cellW = size.width / n;
    final cellH = size.height / n;
    final centers = <Offset>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        centers.add(Offset(cellW * c + cellW / 2, cellH * r + cellH / 2));
      }
    }
    return centers;
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _selected.clear();
      _complete = false;
      _currentPoint = d.localPosition;
    });
    _checkHit(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_complete) return;
    setState(() => _currentPoint = d.localPosition);
    _checkHit(d.localPosition);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_selected.length >= 4) {
      setState(() {
        _complete = true;
        _currentPoint = null;
      });
      widget.onComplete(_selected.join('-'));
    } else {
      setState(() {
        _selected.clear();
        _complete = false;
        _currentPoint = null;
      });
    }
  }

  void _checkHit(Offset pos) {
    if (_widgetSize == Size.zero) return;
    final centers = _getDotCenters(_widgetSize);
    for (int i = 0; i < centers.length; i++) {
      if (_selected.contains(i)) continue;
      if ((pos - centers[i]).distance < _hitRadius) {
        setState(() => _selected.add(i));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activeColor ?? AppColors.accent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxWidth);
        _widgetSize = size;
        final centers = _getDotCenters(size);
        final selectedCenters = _selected.map((i) => centers[i]).toList();

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: CustomPaint(
              painter: _PatternPainter(
                points: selectedCenters,
                currentPoint: _complete ? null : _currentPoint,
                color: color,
              ),
              child: Stack(
                children: List.generate(widget.gridSize * widget.gridSize, (i) {
                  final center = centers[i];
                  final active = _selected.contains(i);
                  final r = active ? _activeDotRadius : _dotRadius;
                  return Positioned(
                    left: center.dx - r,
                    top: center.dy - r,
                    width: r * 2,
                    height: r * 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: active ? color : Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: active
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<Offset> points;
  final Offset? currentPoint;
  final Color color;

  _PatternPainter(
      {required this.points, this.currentPoint, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color.withOpacity(0.65)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
    if (currentPoint != null && points.isNotEmpty) {
      canvas.drawLine(points.last, currentPoint!, paint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.points != points || old.currentPoint != currentPoint;
}
