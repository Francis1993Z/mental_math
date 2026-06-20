import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Reusable LaTeX renderer wrapping [Math.tex] with:
/// - graceful error handling (falls back to the raw string if LaTeX is invalid)
/// - adaptive font sizing that shrinks to fit the available width
///
/// All formulas in the Algebre & Trigo mode (prompts and answer choices) are
/// stored as LaTeX strings and rendered through this widget.
class MathText extends StatelessWidget {
  final String latex;
  final double fontSize;

  /// Minimum font size used while auto-shrinking to fit the width.
  final double minFontSize;
  final Color? color;
  final TextAlign textAlign;

  const MathText(
    this.latex, {
    super.key,
    this.fontSize = 28,
    this.minFontSize = 12,
    this.color,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : double.infinity,
            ),
            child: Math.tex(
              latex,
              textStyle: TextStyle(fontSize: fontSize, color: effectiveColor),
              textScaleFactor: 1.0,
              onErrorFallback: (err) => _fallback(effectiveColor),
            ),
          ),
        );
      },
    );
  }

  /// Plain-text fallback shown when the LaTeX cannot be parsed.
  Widget _fallback(Color color) {
    return Text(
      latex,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize * 0.7,
        color: color,
        fontFamily: 'monospace',
      ),
    );
  }
}
