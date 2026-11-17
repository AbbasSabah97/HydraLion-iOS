# HydraLion for Android

Native Android companion to [HydraLion iOS](https://github.com/AbbasSabah97/HydraLion-iOS). Built with Kotlin and Jetpack Compose.

## Device target

- Target device: Android 11 (API 30)
- Requested software: MIUI Global 12.5.2 / Android 11
- minSdk: 23
- compileSdk: 35
- targetSdk: 30
- Package: `com.abbassabah.hydralion`

The APK is a native Android app, not a web wrapper.

## Features

- Glass-style bottle home screen with a frame-clock-driven continuous water surface and individually rising bubbles; the wave timeline does not restart at a fixed interval.
- Original transparent mascot artwork and the exact iOS AppIcon; iOS-style vector drink icons with corrected Tea, Juice, Milk and Water labels.
- Add water, green tea, coffee, orange juice and milk; serving presets and a persistent celebration state.
- History with day, 7-day and 30-day views, edit and delete.
- Progress ring, consumed amount, remaining amount and configurable daily goal.
- Local reminders with interval, start/end time, custom message, sound and snooze.
- Local offline storage and reminder restoration after reboot.
- Arabic/English UI based on the device language.

The Android build copies the same AppIcon and six transparent mascot PNGs directly from the sibling iOS asset catalog during the Gradle build, then bundles them into the APK. The installed application does not load assets from the network.

## Build

Open the `android/` directory in Android Studio with Gradle 8.9, or run:

```bash
gradle --no-daemon :app:assembleDebug
```

The build copies the original mascot and icon assets from the iOS repository's checked-out asset catalog.

Output:

`android/app/build/outputs/apk/debug/app-debug.apk`

GitHub Actions builds the APK automatically. Open the Actions tab and download the `HydraLion-Android-v1.0.1` artifact.

## MIUI notification setup

For reminders to arrive reliably while the screen is locked:

1. Enable HydraLion under **Settings → Apps → Permissions → Autostart** (wording can vary by MIUI build).
2. Open **Settings → Battery → App battery saver → HydraLion** and select **No restrictions**.
3. Allow HydraLion notifications and sound in system notification settings.
4. Keep the reminder switch enabled inside the app.

Android and MIUI power-management policies can still defer alarms in some circumstances. The app schedules local exact alarms and restores the schedule after device reboot; it cannot override a user-disabled notification channel or MIUI restrictions.

## Notes

- User data stays on the device in app-private storage.
- Notification scheduling is local; there is no push-notification server.
- The CI artifact is a debug-signed APK suitable for direct installation/testing. A Play Store release should use a separately managed release signing key.
