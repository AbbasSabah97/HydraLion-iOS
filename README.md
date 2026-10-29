# HydraLion — Water Reminder for iPhone

Native SwiftUI iOS 16+ app built using the **exact six transparent mascot PNGs** supplied by the user. Screen mockups in `DesignReferences/` are design references only: the UI is functional SwiftUI, not screenshots.

## Screens

1. Home: bottle fill animates with the current daily intake; add button, history and progress.
2. Water Reminder: circular progress, remaining quantity, water/tea breakdown.
3. Add Drink: water, tea, coffee, juice and milk, adjustable serving sizes and animated mascot.
4. History: daily list, weekly/monthly summary, edit/delete entries.
5. Reminders: permission-aware local notifications, interval, start/end, sound, message and snooze.

All data persists offline in UserDefaults. Daily goal defaults to **3000 ml** and is editable. UI follows the supplied reference palette; no remote tracking or account is required.

## Build from this ZIP

Open `HydraLion.xcodeproj` in Xcode 16 or newer on a Mac. Select the `HydraLion` scheme, choose an iPhone target, then Product → Archive. For a signed IPA, select a development team and use **Distribute App** to export it with a certificate/profile valid for the intended iPhone(s). Bundle ID defaults to `com.abbassabah.hydralion` (change if already in use).

## GitHub Actions / Windows workflow

On Windows you can simply run `PUSH-TO-GITHUB.ps1` (after extracting the ZIP) to clone your connected `WaterReminder` repository and push the iOS app into a new branch. Or place the complete project inside your repo as `ios/` (including `HydraLion.xcodeproj`, `HydraLion/Assets.xcassets` and PNGs), and place `.github/workflows/ios-ipa.yml` at repository root. In **Actions**, run **HydraLion iOS IPA**. It builds for iOS Simulator and creates a device `.xcarchive` and `HydraLion-UNSIGNED.ipa` in an artifact. **This IPA is deliberately unsigned and cannot be installed on a normal iPhone until signed with a legitimate Apple certificate and provisioning profile**. Use your Windows sideload application (if it supports signing an unsigned IPA) to sign it under your own Apple credentials; no claim of indefinite free signing validity is made.

To distribute a fully signed IPA in CI, configure Apple signing certificates and matching provisioning profiles as GitHub Secrets, or export via Xcode. Do **not** commit certificates, passwords, or Apple ID credentials to the repository.

## Assets and reference

- `MascotIdle`, `MascotBlink`, `MascotDrink`, `MascotCheers`, `MascotSurprised`, `MascotRelax`: exactly the uploaded characters, no redrawing.
- `AppIcon`: 1024×1024 PNG with the character's face.
- `DesignReferences`: originals of the five supplied screens.

## Implementation note

This environment cannot run Apple's `xcodebuild` because it is Linux. GitHub Actions on macOS or a Mac with Xcode is necessary to confirm successful compilation and produce the archive. You can syntax-check the source with `swiftc -frontend -parse HydraLion/*.swift` on a Swift installation.
