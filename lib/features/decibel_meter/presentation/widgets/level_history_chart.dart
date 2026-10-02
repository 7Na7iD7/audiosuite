import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class LevelHistoryChart extends StatelessWidget {
  const LevelHistoryChart({super.key, required this.values, this.height = 90});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(painter: _HistoryPainter(values)),
      ),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..strokeWidth = 1
      ..color = AppColors.outline;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;

    const range = AudioConstants.splMax - AudioConstants.splMin;
    final step = size.width / (AudioConstants.meterHistoryLength - 1);
    final offset = (AudioConstants.meterHistoryLength - values.length) * step;
    final line = Path();
    final area = Path();
    for (var i = 0; i < values.length; i++) {
      final x = offset + i * step;
      final y = size.height -
          ((values[i] - AudioConstants.splMin) / range).clamp(0.0, 1.0) *
              size.height;
      if (i == 0) {
        line.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area.lineTo(offset + (values.length - 1) * step, size.height);
    area.close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0.28),
            AppColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) =>
      oldDelegate.values != values;
}
