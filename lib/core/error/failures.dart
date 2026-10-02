import 'package:audiosuite/core/l10n/app_strings.dart';

sealed class AudioFailure implements Exception {
  const AudioFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class MicrophonePermissionFailure extends AudioFailure {
  const MicrophonePermissionFailure() : super(AppStrings.errMicPermission);
}

final class AudioDeviceFailure extends AudioFailure {
  const AudioDeviceFailure([super.message = AppStrings.errDevice]);
}

final class StorageFailure extends AudioFailure {
  const StorageFailure([super.message = AppStrings.errStorage]);
}

final class RecordingTooShortFailure extends AudioFailure {
  const RecordingTooShortFailure() : super(AppStrings.errTooShort);
}
