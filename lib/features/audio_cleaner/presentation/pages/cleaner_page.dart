import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/core/theme/app_colors.dart';
import 'package:audiosuite/core/utils/format.dart';
import 'package:audiosuite/core/widgets/page_header.dart';
import 'package:audiosuite/core/widgets/round_action_button.dart';
import 'package:audiosuite/core/widgets/surface_card.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaner_state.dart';
import 'package:audiosuite/features/audio_cleaner/presentation/providers/cleaner_providers.dart';
import 'package:audiosuite/features/audio_cleaner/presentation/widgets/input_level_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CleanerPage extends ConsumerWidget {
  const CleanerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanerControllerProvider);
    final controller = ref.read(cleanerControllerProvider.notifier);

    ref.listen(cleanerControllerProvider.select((s) => (s.error, s.info)),
        (_, message) {
      final text = message.$1 ?? message.$2;
      if (text != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text)));
        controller.clearMessages();
      }
    });

    final busy = state.status == CleanerStatus.saving ||
        state.status == CleanerStatus.starting;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const PageHeader(
            title: AppStrings.cleanerTitle,
            subtitle: AppStrings.cleanerSubtitle,
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              children: [
                Text(
                  formatDuration(state.elapsed),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                InputLevelBar(level: state.level, active: state.isRecording),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundActionButton(
                      icon: state.isRecording
                          ? Icons.stop_rounded
                          : Icons.fiber_manual_record_rounded,
                      color: state.isRecording
                          ? AppColors.danger
                          : AppColors.accent,
                      loading: busy,
                      onPressed: controller.toggleRecording,
                    ),
                    if (state.isRecording) ...[
                      const SizedBox(width: 18),
                      IconButton.outlined(
                        onPressed: controller.cancelRecording,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  state.status == CleanerStatus.saving
                      ? AppStrings.saving
                      : state.isRecording
                          ? AppStrings.stopRecording
                          : AppStrings.startRecording,
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
                      Icons.tune_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.sensitivity,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${(state.threshold * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Slider(
                  value: state.threshold,
                  onChanged: state.status == CleanerStatus.idle
                      ? controller.setThreshold
                      : null,
                ),
                Text(
                  AppStrings.cleanerHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.recordings,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (state.recordings.isEmpty)
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  AppStrings.emptyRecordings,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            for (final recording in state.recordings)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecordingTile(
                  recording: recording,
                  state: state,
                  onToggle: () => controller.togglePlayback(recording),
                  onShare: () => controller.export(recording),
                  onDelete: () => controller.delete(recording),
                ),
              ),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({
    required this.recording,
    required this.state,
    required this.onToggle,
    required this.onShare,
    required this.onDelete,
  });

  final CleanedRecording recording;
  final CleanerState state;
  final VoidCallback onToggle;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final current = state.playback.path == recording.path;
    final playing = current && state.playback.playing;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      borderColor:
          current ? AppColors.accent.withValues(alpha: 0.5) : AppColors.outline,
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceHigh,
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTimestamp(recording.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDuration(recording.duration)}  •  ${formatBytes(recording.sizeBytes)}  •  WAV',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.surfaceHigh,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'share') onShare();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'share', child: Text(AppStrings.share)),
                  PopupMenuItem(
                      value: 'delete', child: Text(AppStrings.delete)),
                ],
              ),
            ],
          ),
          if (current) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: LinearProgressIndicator(
                value: state.playback.progress,
                minHeight: 3,
                backgroundColor: AppColors.outline,
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
