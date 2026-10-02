import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RoundActionButton extends StatelessWidget {
  const RoundActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 76,
    this.color = AppColors.accent,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: loading
            ? Padding(
                padding: EdgeInsets.all(size * 0.3),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.background,
                ),
              )
            : Icon(icon, size: size * 0.46, color: AppColors.background),
      ),
    );
  }
}
