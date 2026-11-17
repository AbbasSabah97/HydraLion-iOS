# HydraLion for Android

Native Android companion to [HydraLion iOS](https://github.com/AbbasSabah97/HydraLion-iOS). Built with Kotlin and Jetpack Compose.

## Device target

- Tested build target: Android 11 (API 30)
- Requested device family: MIUI Global 12.5.2 / Android 11
- minSdk: 23
- compileSdk: 35
- targetSdk: 30
- Package: `com.abbassabah.hydralion`

The APK is a native Android app, not a web wrapper.

## Features

- Home screen with a glass-style bottle, animated continuous water surface, rising bubbles and the original transparent mascot artwork.
- Add water, green tea, coffee, orange juice and milk; select 50 ml increments or 150/250/330/500 ml presets.
- Celebration mascot remains visible after adding a drink until the user leaves the screen.
- Daily history with day, 7-day and 30-day views, including edit and delete.
- Progress ring, consumed amount, remaining amount and configurable daily goal (250–10,000 ml).
- Local reminders with interval, start/end time, custom message, sound and snooze.
- Local storage. No account or internet connection is needed after installation.

The Android build downloads the same AppIcon and six transparent mascot PNGs from the iOS asset catalog during the Gradle build, then bundles them into the APK. The installed application does not load those assets from the network.

## Build

Open the `android/` directory in Android Studio, or run:

```bash
gradle --no-daemon :app:assembleDebug
```

The build downloads the original mascot and icon assets from the iOS repository. Output:

`android/app/build/outputs/apk/debug/app-debug.apk`

GitHub Actions builds the APK automatically when Android files change. Open the Actions tab and download the `HydraLion-Android-v1.0.0` artifact.

## MIUI notification setup

For reminders to arrive reliably while the screen is locked:

1. Enable HydraLion under **Settings → Apps → Permissions → Autostart** (wording can vary by MIUI build).
2. Open **Settings → Battery → App battery saver → HydraLion** and select **No restrictions**.
3. Allow HydraLion notifications and sound in the system notification settings.
4. Keep the reminder switch enabled inside the app.

Android and MIUI power-management policies can still defer alarms in some circumstances. The app schedules local exact alarms and restores the schedule after device reboot; it cannot override a user-disabled notification channel or MIUI restrictions.

## Notes

- User data stays on the device in app-private storage.
- Notification scheduling is local; there is no push-notification server.
- The CI artifact is a debug-signed APK suitable for direct installation/testing. A Play Store release should use a separately managed release signing key.
