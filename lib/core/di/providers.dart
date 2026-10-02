import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/audio/audio_manager.dart';
import 'package:audiosuite/features/noise_generator/data/services/noise_audio_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioManagerProvider = Provider<AudioManager>((ref) {
  final manager = AudioManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final noiseAudioHandlerProvider = Provider<NoiseAudioHandler>(
  (ref) =>
      throw UnimplementedError('noiseAudioHandlerProvider must be overridden'),
);

final currentTabProvider =
    NotifierProvider<AppTabNotifier, AppTab>(AppTabNotifier.new);

class AppTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.noise;

  Future<void> select(AppTab tab) async {
    if (tab == state) return;
    await ref.read(audioManagerProvider).onTabChanged(tab);
    state = tab;
  }
}
