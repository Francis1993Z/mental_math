import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

/// Plots a single-variable function from its string [expression] (variable
/// `x`), evaluated with math_expressions and drawn with a [CustomPainter].
///
/// Handles polynomials and rational functions: vertical asymptotes / large
/// jumps break the stroke instead of drawing a spurious vertical line.
class FunctionPlot extends StatefulWidget {
  final String expression;
  final double xMin;
  final double xMax;
  final double? yMin;
  final double? yMax;

  const FunctionPlot({
    super.key,
    required this.expression,
    required this.xMin,
    required this.xMax,
    this.yMin,
    this.yMax,
  });

  @override
  State<FunctionPlot> createState() => _FunctionPlotState();
}

class _FunctionPlotState extends State<FunctionPlot> {
  static const int _samples = 400;

  List<Offset?> _points = const [];
  double _yMin = -10;
  double _yMax = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void didUpdateWidget(FunctionPlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression ||
        oldWidget.xMin != widget.xMin ||
        oldWidget.xMax != widget.xMax) {
      _compute();
    }
  }

  void _compute() {
    try {
      final parser = GrammarParser();
      final exp = parser.parse(widget.expression);
      final context = ContextModel();
      final evaluator = RealEvaluator(context);

      final raw = <Offset?>[];
      final finiteYs = <double>[];
      for (int i = 0; i <= _samples; i++) {
        final x = widget.xMin + (widget.xMax - widget.xMin) * i / _samples;
        context.bindVariableName('x', Number(x));
        double y;
        try {
          y = evaluator.evaluate(exp).toDouble();
        } catch (_) {
          raw.add(null);
          continue;
        }
        if (y.isFinite && y.abs() < 1e7) {
          raw.add(Offset(x, y));
          finiteYs.add(y);
        } else {
          raw.add(null);
        }
      }

      double yMin;
      double yMax;
      if (widget.yMin != null && widget.yMax != null) {
        yMin = widget.yMin!;
        yMax = widget.yMax!;
      } else if (finiteYs.isNotEmpty) {
        finiteYs.sort();
        // Use robust percentiles to avoid asymptote spikes dominating.
        final lo = finiteYs[(finiteYs.length * 0.02).floor()];
        final hi = finiteYs[(finiteYs.length * 0.98).floor().clamp(0, finiteYs.length - 1)];
        final pad = math.max((hi - lo) * 0.12, 1.0);
        yMin = lo - pad;
        yMax = hi + pad;
      } else {
        yMin = -10;
        yMax = 10;
      }
      if (yMax - yMin < 1e-6) {
        yMin -= 1;
        yMax += 1;
      }

      setState(() {
        _points = raw;
        _yMin = yMin;
        _yMax = yMax;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Impossible de tracer cette fonction.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _PlotPainter(
            points: _points,
            xMin: widget.xMin,
            xMax: widget.xMax,
            yMin: _yMin,
            yMax: _yMax,
            curveColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _PlotPainter extends CustomPainter {
  final List<Offset?> points;
  final double xMin, xMax, yMin, yMax;
  final Color curveColor;

  _PlotPainter({
    required this.points,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.curveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    double sx(double x) => (x - xMin) / (xMax - xMin) * size.width;
    double sy(double y) => size.height - (y - yMin) / (yMax - yMin) * size.height;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.6;

    // Vertical grid lines at integer x.
    for (int x = xMin.ceil(); x <= xMax.floor(); x++) {
      final px = sx(x.toDouble());
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), gridPaint);
    }
    // Horizontal grid lines at integer y (skip if too dense).
    final yStep = ((yMax - yMin) / 10).ceil().clamp(1, 1000);
    for (int y = yMin.ceil(); y <= yMax.floor(); y += yStep) {
      final py = sy(y.toDouble());
      canvas.drawLine(Offset(0, py), Offset(size.width, py), gridPaint);
    }

    // Axes through origin (if visible).
    if (xMin <= 0 && xMax >= 0) {
      final px = sx(0);
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), axisPaint);
    }
    if (yMin <= 0 && yMax >= 0) {
      final py = sy(0);
      canvas.drawLine(Offset(0, py), Offset(size.width, py), axisPaint);
    }

    _drawAxisLabels(canvas, size, sx, sy, yStep);

    // The curve. Break the path on null points or large jumps.
    final curvePaint = Paint()
      ..color = curveColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();
    bool penDown = false;
    Offset? prevScreen;
    final jumpLimit = size.height * 1.5;
    for (final p in points) {
      if (p == null) {
        penDown = false;
        prevScreen = null;
        continue;
      }
      final screen = Offset(sx(p.dx), sy(p.dy));
      if (!penDown) {
        path.moveTo(screen.dx, screen.dy);
        penDown = true;
      } else {
        if (prevScreen != null && (screen.dy - prevScreen.dy).abs() > jumpLimit) {
          // Likely an asymptote: lift the pen.
          path.moveTo(screen.dx, screen.dy);
        } else {
          path.lineTo(screen.dx, screen.dy);
        }
      }
      prevScreen = screen;
    }
    canvas.drawPath(path, curvePaint);
  }

  void _drawAxisLabels(Canvas canvas, Size size, double Function(double) sx,
      double Function(double) sy, int yStep) {
    final originY = (yMin <= 0 && yMax >= 0) ? sy(0) : size.height - 2;
    final originX = (xMin <= 0 && xMax >= 0) ? sx(0) : 2;

    for (int x = xMin.ceil(); x <= xMax.floor(); x++) {
      if (x == 0) continue;
      _label(canvas, '$x', Offset(sx(x.toDouble()) + 2, originY + 2));
    }
    for (int y = yMin.ceil(); y <= yMax.floor(); y += yStep) {
      if (y == 0) continue;
      _label(canvas, '$y', Offset(originX + 3, sy(y.toDouble()) + 1));
    }
  }

  void _label(Canvas canvas, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_PlotPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.xMin != xMin ||
      oldDelegate.xMax != xMax ||
      oldDelegate.yMin != yMin ||
      oldDelegate.yMax != yMax;
}
