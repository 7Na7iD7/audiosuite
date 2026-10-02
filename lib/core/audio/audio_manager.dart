import 'dart:async';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/audio/pcm_converter.dart';
import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:record/record.dart';

typedef PreemptionHandler = Future<void> Function();

final class AudioManager {
  AudioManager({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final Map<AudioChannel, PreemptionHandler> _handlers = {};
  final Set<AudioChannel> _active = {};
  final StreamController<AudioChannel?> _ownerController =
  StreamController<AudioChannel?>.broadcast();

  StreamController<Float32List>? _pcmController;
  StreamSubscription<Uint8List>? _pcmSubscription;
  AudioChannel? _microphoneOwner;
  Future<void> _tail = Future<void>.value();

  AudioChannel? get microphoneOwner => _microphoneOwner;

  Stream<AudioChannel?> get microphoneOwnerChanges => _ownerController.stream;

  bool isActive(AudioChannel channel) => _active.contains(channel);

  void registerPreemptionHandler(
      AudioChannel channel,
      PreemptionHandler handler,
      ) {
    _handlers[channel] = handler;
  }

  void unregisterPreemptionHandler(AudioChannel channel) {
    _handlers.remove(channel);
  }

  Future<void> claim(AudioChannel channel) async {
    await _preemptConflicts(channel);
    _active.add(channel);
  }

  void release(AudioChannel channel) {
    if (channel.usesMicrophone) return;
    _active.remove(channel);
  }

  Future<Stream<Float32List>> openMicrophone(
      AudioChannel channel, {
        int sampleRate = AudioConstants.micSampleRate,
      }) async {
    assert(channel.usesMicrophone);
    await _preemptConflicts(channel);
    return _synchronized(() async {
      await _stopCapture();
      if (!await _recorder.hasPermission()) {
        throw const MicrophonePermissionFailure();
      }
      try {
        await _configureSession(capture: true);
        final controller = StreamController<Float32List>.broadcast();
        final converter = PcmConverter();
        final raw = await _recorder.startStream(
          RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: sampleRate,
            numChannels: 1,
            autoGain: false,
            echoCancel: false,
            noiseSuppress: false,
          ),
        );
        _pcmController = controller;
        _pcmSubscription = raw.listen(
              (bytes) {
            final samples = converter.convert(bytes);
            if (samples.isNotEmpty && !controller.isClosed) {
              controller.add(samples);
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!controller.isClosed) controller.addError(error, stack);
          },
          onDone: () {
            if (!controller.isClosed) controller.close();
          },
        );
        _microphoneOwner = channel;
        _active.add(channel);
        _ownerController.add(channel);
        return controller.stream;
      } on AudioFailure {
        rethrow;
      } catch (_) {
        await _stopCapture();
        throw const AudioDeviceFailure();
      }
    });
  }

  Future<void> closeMicrophone(AudioChannel channel) {
    return _synchronized(() async {
      if (_microphoneOwner != channel) return;
      await _stopCapture();
      await _configureSession(capture: false);
    });
  }

  Future<void> releaseMicrophone() {
    return _synchronized(() async {
      if (_microphoneOwner == null) return;
      await _stopCapture();
      await _configureSession(capture: false);
    });
  }

  Future<void> onTabChanged(AppTab tab) async {
    final allowed = tab.allowedChannels;
    for (final channel in _active.toList()) {
      if (!allowed.contains(channel)) {
        await _handlers[channel]?.call();
      }
    }
    if (tab == AppTab.noise) {
      await releaseMicrophone();
    }
  }

  Future<void> onAppBackgrounded() async {
    for (final channel in _active.toList()) {
      if (channel.usesMicrophone || channel == AudioChannel.cleanerPlayback) {
        await _handlers[channel]?.call();
      }
    }
    await releaseMicrophone();
  }

  Future<void> dispose() async {
    await releaseMicrophone();
    await _recorder.dispose();
    await _ownerController.close();
  }

  Future<void> _preemptConflicts(AudioChannel channel) async {
    for (final other in channel.conflicts) {
      if (_active.contains(other)) {
        await _handlers[other]?.call();
        _active.remove(other);
      }
    }
  }

  Future<void> _stopCapture() async {
    final subscription = _pcmSubscription;
    final controller = _pcmController;
    final owner = _microphoneOwner;
    _pcmSubscription = null;
    _pcmController = null;
    _microphoneOwner = null;
    if (owner != null) _active.remove(owner);
    await subscription?.cancel();
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    if (owner != null) _ownerController.add(null);
  }

  Future<void> _configureSession({required bool capture}) async {
    try {
      final session = await AudioSession.instance;
      if (capture) {
        await session.configure(
          AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.allowBluetooth,
            avAudioSessionMode: AVAudioSessionMode.measurement,
            androidAudioAttributes: const AndroidAudioAttributes(
              contentType: AndroidAudioContentType.speech,
              usage: AndroidAudioUsage.media,
            ),
            androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          ),
        );
      } else {
        await session.configure(const AudioSessionConfiguration.music());
      }
    } catch (_) {}
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}