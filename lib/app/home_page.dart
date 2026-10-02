import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/di/providers.dart';
import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/features/audio_cleaner/presentation/pages/cleaner_page.dart';
import 'package:audiosuite/features/decibel_meter/presentation/pages/meter_page.dart';
import 'package:audiosuite/features/noise_generator/presentation/pages/noise_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(audioManagerProvider).onAppBackgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentTabProvider);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(tab),
          child: switch (tab) {
            AppTab.noise => const NoisePage(),
            AppTab.meter => const MeterPage(),
            AppTab.cleaner => const CleanerPage(),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (index) =>
            ref.read(currentTabProvider.notifier).select(AppTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_rounded),
            label: AppStrings.tabNoise,
          ),
          NavigationDestination(
            icon: Icon(Icons.speed_rounded),
            label: AppStrings.tabMeter,
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            label: AppStrings.tabCleaner,
          ),
        ],
      ),
    );
  }
}
