import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class InputLevelBar extends StatelessWidget {
  const InputLevelBar({super.key, required this.level, required this.active});

  final double level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fraction = active ? ((level + 70) / 70).clamp(0.0, 1.0) : 0.0;
    final color = fraction > 0.85
        ? AppColors.danger
        : fraction > 0.65
            ? AppColors.warning
            : AppColors.accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: const Duration(milliseconds: 120),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surfaceHigh,
            color: color,
          ),
        ),
      ),
    );
  }
}
