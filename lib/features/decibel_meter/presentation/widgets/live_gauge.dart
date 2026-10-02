import 'dart:math' as math;

import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LiveGauge extends StatefulWidget {
  const LiveGauge({
    super.key,
    required this.value,
    required this.active,
    required this.label,
  });

  final double value;
  final bool active;
  final String label;

  @override
  State<LiveGauge> createState() => _LiveGaugeState();
}

class _LiveGaugeState extends State<LiveGauge>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ValueNotifier<double> _display;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _display = ValueNotifier(widget.active ? widget.value : 0);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final target = widget.active ? widget.value : 0.0;
    final delta = target - _display.value;
    if (delta.abs() < 0.02) {
      if (_display.value != target) _display.value = target;
      return;
    }
    _display.value += delta * (1 - math.exp(-dt * 14));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _display.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _GaugePainter(_display)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _display,
                  builder: (context, value, _) => Text(
                    widget.active ? value.round().toString() : '--',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'dB',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value) : super(repaint: value);

  final ValueNotifier<double> value;

  static const double _start = math.pi * 0.75;
  static const double _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.06;
    final radius = size.shortestSide / 2 - stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceHigh;
    canvas.drawArc(rect, _start, _sweep, false, track);

    final fraction = ((value.value - AudioConstants.splMin) /
            (AudioConstants.splMax - AudioConstants.splMin))
        .clamp(0.0, 1.0);

    if (fraction > 0.004) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: _start,
          endAngle: _start + _sweep,
          colors: [
            AppColors.accent,
            AppColors.success,
            AppColors.warning,
            AppColors.danger,
          ],
          stops: [0.0, 0.4, 0.68, 1.0],
          transform: GradientRotation(0),
        ).createShader(rect);
      canvas.drawArc(rect, _start, _sweep * fraction, false, progress);

      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..color = AppColors.accent.withValues(alpha: 0.18);
      canvas.drawArc(rect, _start, _sweep * fraction, false, glow);
    }

    final tick = Paint()
      ..strokeWidth = 1.5
      ..color = AppColors.outline;
    const ticks = 27;
    for (var i = 0; i <= ticks; i++) {
      final angle = _start + _sweep * (i / ticks);
      final major = i % 3 == 0;
      final outer = radius - stroke * 1.4;
      final inner = outer - (major ? stroke * 0.9 : stroke * 0.45);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => false;
}
