import 'package:audio_service/audio_service.dart';
import 'package:audiosuite/app/app.dart';
import 'package:audiosuite/core/di/providers.dart';
import 'package:audiosuite/features/noise_generator/data/services/noise_audio_handler.dart';
import 'package:audiosuite/src/rust/frb_generated.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF12161B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final handler = await AudioService.init<NoiseAudioHandler>(
    builder: NoiseAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.navid.audiosuite.playback',
      androidNotificationChannelName: 'AudioSuite',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [noiseAudioHandlerProvider.overrideWithValue(handler)],
      child: const AudioSuiteApp(),
    ),
  );
}