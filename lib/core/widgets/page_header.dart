import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
