# AudioSuite

ابزار صوتی سه‌کاره با Flutter (رابط کاربری) و Rust (پردازش سیگنال با تأخیر کم) از طریق `flutter_rust_bridge` نسخه ۲.

## ماژول‌ها

- مولد نویز: نویز سفید، صورتی و قهوه‌ای که در Rust ساخته می‌شود، پخش پس‌زمینه با `audio_service`، کنترل جداگانه صدا و تایمر خواب همراه با فید خروجی
- دسی‌بل‌متر: دریافت PCM از میکروفون، محاسبه RMS و dB در Rust، نمایش گیج زنده با انیمیشن ۶۰ فریم بر ثانیه و آمار کمینه/میانگین/بیشینه
- نویزگیر: حذف نویز لحظه‌ای با Spectral Subtraction و Noise Gate در Rust، ذخیره WAV، پخش و خروجی گرفتن

## ساختار

```
lib/
  main.dart
  app/                      app.dart, home_page.dart
  core/
    audio/                  audio_manager.dart, audio_channel.dart, pcm_converter.dart
    constants/ di/ error/ l10n/ theme/ utils/ widgets/
  features/
    noise_generator/        domain / data / presentation
    decibel_meter/          domain / data / presentation
    audio_cleaner/          domain / data / presentation
  src/rust/                 خروجی تولیدشده توسط codegen
native/
  Cargo.toml
  src/
    lib.rs
    api/audio.rs            واسط پل (calculate_db, process_audio_chunk, ...)
    dsp/                    level, noise, denoiser, wav
test/
```

## راه‌اندازی

پیش‌نیازها: Flutter 3.22 یا بالاتر، Rust stable، Android NDK، Xcode برای iOS.

۱. نصب codegen با همان نسخه‌ای که در `pubspec.yaml` و `Cargo.toml` قفل شده است:

```
cargo install flutter_rust_bridge_codegen --version 2.11.1
```

۲. ساخت پروژه‌ی Flutter و افزودن اسکلت پل:

```
flutter create --org com.navid --project-name audiosuite audiosuite
cd audiosuite
flutter_rust_bridge_codegen integrate --rust-crate-dir native
```

این دستور پوشه‌ی `rust_builder` را می‌سازد. اگر پرچم `--rust-crate-dir` در نسخه‌ی شما پشتیبانی نشد، پوشه‌ی `rust` ساخته‌شده را به `native` تغییر نام دهید و مسیر `../../rust` را در `rust_builder` (فایل‌های `android/build.gradle` و `ios`/`macos` podspec) به `../../native` تغییر دهید.

۳. محتویات این zip را روی پروژه کپی و فایل‌های موجود را جایگزین کنید (`pubspec.yaml`, `lib/`, `native/`, `flutter_rust_bridge.yaml`, `analysis_options.yaml`, `test/`).

۴. نصب پکیج‌ها و تولید کد پل:

```
flutter pub get
flutter_rust_bridge_codegen generate
```

۵. اجرا:

```
flutter run
```

برای تست Rust: `cd native && cargo test` (فایل `frb_generated.rs` پس از generate ساخته می‌شود).

## تنظیمات پلتفرم

اندروید، `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

داخل تگ `<application>`:

```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>
<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

در `MainActivity` کلاس والد را به `AudioServiceActivity` تغییر دهید:

```kotlin
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity()
```

در `android/app/build.gradle` مقدار `minSdkVersion` را روی ۲۴ بگذارید.

iOS، `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>برای اندازه‌گیری و ضبط صدا به میکروفون نیاز است</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## نکات معماری

- `AudioManager` تنها نقطه‌ی دسترسی به میکروفون است. کانال‌های `meter` و `cleanerRecording` و `cleanerPlayback` با هم ناسازگارند و ورود هر کدام، دیگری را از طریق Preemption Handler متوقف می‌کند.
- با رفتن به تب نویز یا به پس‌زمینه رفتن برنامه، میکروفون بلافاصله آزاد می‌شود.
- تمام DSP سنگین در Rust و روی thread pool خود پل اجرا می‌شود و رشته‌ی UI فقط بافر را می‌فرستد و عدد نهایی را می‌گیرد.
- مقدار `calculate_db` برحسب dBFS است. ثابت `dbCalibrationOffset` در `AudioConstants` آن را به مقدار تقریبی SPL تبدیل می‌کند و برای دقت بیشتر باید با دستگاه مرجع کالیبره شود.
- خروجی ضبط‌ها WAV تک‌کاناله ۱۶ بیتی است.
