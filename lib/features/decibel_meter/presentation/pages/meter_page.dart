import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:audiosuite/core/widgets/page_header.dart';
import 'package:audiosuite/core/widgets/round_action_button.dart';
import 'package:audiosuite/core/widgets/surface_card.dart';
import 'package:audiosuite/features/decibel_meter/domain/entities/meter_state.dart';
import 'package:audiosuite/features/decibel_meter/presentation/providers/meter_providers.dart';
import 'package:audiosuite/features/decibel_meter/presentation/widgets/level_history_chart.dart';
import 'package:audiosuite/features/decibel_meter/presentation/widgets/live_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _levelLabel(MeterState state) {
  if (!state.isRunning) return AppStrings.idleLevel;
  final db = state.db;
  if (db < 30) return AppStrings.levelQuiet;
  if (db < 50) return AppStrings.levelCalm;
  if (db < 70) return AppStrings.levelNormal;
  if (db < 85) return AppStrings.levelLoud;
  return AppStrings.levelDanger;
}

class MeterPage extends ConsumerWidget {
  const MeterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meterControllerProvider);
    final controller = ref.read(meterControllerProvider.notifier);

    ref.listen(meterControllerProvider.select((s) => s.error), (_, error) {
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
            title: AppStrings.meterTitle,
            subtitle: AppStrings.meterSubtitle,
          ),
          const SizedBox(height: 12),
          LiveGauge(
            value: state.db,
            active: state.isRunning,
            label: _levelLabel(state),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(label: AppStrings.min, value: state.min),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(label: AppStrings.avg, value: state.average),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(label: AppStrings.max, value: state.max),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: LevelHistoryChart(values: state.history),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoundActionButton(
                icon: state.isRunning ? Icons.stop_rounded : Icons.mic_rounded,
                color: state.isRunning ? AppColors.danger : AppColors.accent,
                loading: state.status == MeterStatus.starting,
                onPressed: controller.toggle,
              ),
              const SizedBox(width: 20),
              IconButton.outlined(
                onPressed: state.min == null ? null : controller.reset,
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: AppStrings.reset,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              state.isRunning ? AppStrings.stopMeter : AppStrings.startMeter,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.calibrationNote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value == null ? '--' : value!.round().toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
