import 'dart:math' as math;

import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class NoiseWaveform extends StatefulWidget {
  const NoiseWaveform({
    super.key,
    required this.color,
    required this.tint,
    required this.active,
    this.height = 120,
  });

  final NoiseColor color;
  final Color tint;
  final bool active;
  final double height;

  @override
  State<NoiseWaveform> createState() => _NoiseWaveformState();
}

class _NoiseWaveformState extends State<NoiseWaveform>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<_Frame> _frame = ValueNotifier(const _Frame(0, 0.08));
  Duration _last = Duration.zero;
  double _phase = 0;
  double _amplitude = 0.08;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final target = widget.active ? 1.0 : 0.08;
    _amplitude += (target - _amplitude) * (1 - math.exp(-dt * 6));
    _phase += dt * (widget.active ? 1.0 : 0.25);
    _frame.value = _Frame(_phase, _amplitude);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WaveformPainter(
            frame: _frame,
            color: widget.color,
            tint: widget.tint,
          ),
        ),
      ),
    );
  }
}

class _Frame {
  const _Frame(this.phase, this.amplitude);

  final double phase;
  final double amplitude;
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.frame,
    required this.color,
    required this.tint,
  }) : super(repaint: frame);

  final ValueNotifier<_Frame> frame;
  final NoiseColor color;
  final Color tint;

  double _sample(double x, double phase) {
    switch (color) {
      case NoiseColor.white:
        return math.sin(x * 190 + phase * 31) *
                math.sin(x * 77 - phase * 53) *
                0.9 +
            math.sin(x * 311 + phase * 97) * 0.35;
      case NoiseColor.pink:
        return math.sin(x * 22 + phase * 5) * 0.55 +
            math.sin(x * 51 - phase * 9) * 0.3 +
            math.sin(x * 113 + phase * 17) * 0.2 +
            math.sin(x * 233 - phase * 29) * 0.12;
      case NoiseColor.brown:
        return math.sin(x * 9 + phase * 2.2) * 0.75 +
            math.sin(x * 21 - phase * 3.1) * 0.25;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final data = frame.value;
    final mid = size.height / 2;
    final path = Path();
    const steps = 160;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final envelope = math.sin(t * math.pi);
      final y = mid -
          _sample(t * 6, data.phase) * data.amplitude * envelope * mid * 0.8;
      final x = t * size.width;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = tint.withValues(alpha: 0.12 * data.amplitude)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = tint;
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tint != tint;
}
