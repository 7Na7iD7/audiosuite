import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:audiosuite/core/utils/format.dart';
import 'package:audiosuite/core/widgets/page_header.dart';
import 'package:audiosuite/core/widgets/round_action_button.dart';
import 'package:audiosuite/core/widgets/surface_card.dart';
import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';
import 'package:audiosuite/features/noise_generator/presentation/providers/noise_providers.dart';
import 'package:audiosuite/features/noise_generator/presentation/widgets/noise_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension on NoiseColor {
  String get label => switch (this) {
        NoiseColor.white => AppStrings.white,
        NoiseColor.pink => AppStrings.pink,
        NoiseColor.brown => AppStrings.brown,
      };

  String get hint => switch (this) {
        NoiseColor.white => AppStrings.whiteHint,
        NoiseColor.pink => AppStrings.pinkHint,
        NoiseColor.brown => AppStrings.brownHint,
      };

  Color get tint => switch (this) {
        NoiseColor.white => AppColors.textPrimary,
        NoiseColor.pink => AppColors.pink,
        NoiseColor.brown => AppColors.brown,
      };
}

class NoisePage extends ConsumerWidget {
  const NoisePage({super.key});

  static const List<int> _timerOptions = [15, 30, 60, 90];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noiseControllerProvider);
    final controller = ref.read(noiseControllerProvider.notifier);

    ref.listen(noiseControllerProvider.select((s) => s.error), (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const PageHeader(
            title: AppStrings.noiseTitle,
            subtitle: AppStrings.noiseSubtitle,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final color in NoiseColor.values) ...[
                Expanded(
                  child: _ColorTile(
                    color: color,
                    selected: color == state.color,
                    onTap: () => controller.selectColor(color),
                  ),
                ),
                if (color != NoiseColor.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.color.hint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                NoiseWaveform(
                  color: state.color,
                  tint: state.color.tint,
                  active: state.isPlaying,
                ),
                const SizedBox(height: 20),
                RoundActionButton(
                  icon: state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  loading: state.isLoading,
                  onPressed: controller.toggle,
                ),
                const SizedBox(height: 10),
                Text(
                  state.isPlaying ? AppStrings.pause : AppStrings.play,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.volume_up_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.volume,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${(state.volume * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Slider(
                  value: state.volume,
                  onChanged: controller.setVolume,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bedtime_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.sleepTimer,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (state.remaining != null)
                      Text(
                        '${AppStrings.remaining}  ${formatDuration(state.remaining!)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TimerChip(
                      label: AppStrings.timerOff,
                      selected: state.timerTotal == null,
                      onTap: () => controller.setSleepTimer(null),
                    ),
                    for (final minutes in _timerOptions)
                      _TimerChip(
                        label: '$minutes دقیقه',
                        selected:
                            state.timerTotal == Duration(minutes: minutes),
                        onTap: () => controller
                            .setSleepTimer(Duration(minutes: minutes)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final NoiseColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = color.tint;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? tint : AppColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.graphic_eq_rounded, color: tint, size: 26),
            const SizedBox(height: 6),
            Text(
              color.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? tint : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
