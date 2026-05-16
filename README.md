# Azure Blob Manager (Flutter)

A lightweight Flutter app to browse, upload, and manage files stored in Azure Blob Storage.

## Screenshots


**Features**
- Browse containers and file lists
- Upload and delete files
- Simple usage analytics and storage charts

**Requirements**
- Flutter SDK (stable)
- Android SDK (platform-tools, build-tools)
- For Android builds: Android NDK (side-by-side). The project targets NDK `28.2.13676358`.

**Setup**
1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Install Android SDK and configure `ANDROID_SDK_ROOT` (or use Android Studio)
3. From project root run:

```
flutter pub get
```

**Run (Android device)**
1. Connect your device and confirm with `flutter devices`.
2. Run the app:

```
flutter run -d <device-id>
```

**Android NDK troubleshooting**
If you see an error like:

```
NDK at C:\Users\<user>\AppData\Local\Android\sdk\ndk\28.2.13676358 did not have a source.properties file
```
Try the following:

1. Delete the malformed NDK folder (replace `<user>` accordingly):

```
rm -rf C:\Users\<user>\AppData\Local\Android\sdk\ndk\28.2.13676358
```

2. From the project root run a clean build so Gradle can re-download it:

```
flutter clean
cd android
./gradlew clean
cd ..
flutter run -d <device-id>
```

If you are on Windows use `del`/PowerShell `Remove-Item` and `gradlew.bat` in the `android` folder.

**Notes**
- Use the correct device id from `adb devices` or `flutter devices` (e.g. `R9YR90F5V6Y`), not the model name.
- If Gradle complains about missing tooling, run the wrapper in the `android` folder: `./gradlew assembleDebug` (or `gradlew.bat` on Windows).

**Contributing**
Feel free to open issues or submit PRs. Keep changes minimal and add tests where appropriate.

**License**
See project root for license information.

---

## Project Overview

`Azure Blob Manager` is a cross-platform Flutter application that provides a simple UI for interacting with Azure Blob Storage. It is intended for small teams and personal projects that need quick file browsing, uploading, and basic analytics.

Key goals:
- Minimal, responsive UI for mobile and desktop
- Simple authentication/configuration via environment variables
- Safe file operations (upload/download/delete) with confirmations

## Architecture

- UI: Flutter widgets under `lib/widgets` and `lib/screens`.
- State & logic: Provider-based state management in `lib/providers`.
- Services: Azure API interactions implemented in `lib/services/azure_blob_service.dart`.
- Models: Data models in `lib/models`.

## Project Structure

The important files and folders for quick navigation and maintenance (ASCII tree):

```
.
├─ pubspec.yaml
├─ README.md
├─ LICENSE
├─ .env.example
├─ android/
│  ├─ gradle/
│  ├─ app/
│  ├─ gradlew
│  ├─ gradlew.bat
│  └─ local.properties
├─ ios/
├─ lib/
│  ├─ main.dart
│  ├─ config/
│  │  └─ app_config.dart
│  ├─ models/
│  │  ├─ file_category.dart
│  │  └─ file_item.dart
│  ├─ providers/
│  │  └─ file_provider.dart
│  ├─ services/
│  │  └─ azure_blob_service.dart
│  ├─ screens/
│  │  └─ dashboard_screen.dart
│  └─ widgets/
│     ├─ category_sidebar.dart
│     ├─ file_list.dart
│     ├─ file_upload_dialog.dart
│     ├─ private_section.dart
│     └─ storage_chart.dart
├─ assets/
│  ├─ icons/
│  └─ docs/
├─ test/
│  └─ widget_test.dart
└─ build/

```

Notes:
- Use `lib/config/app_config.dart` to change how environment variables are loaded (SAS tokens, account keys).
- To change the Android NDK version, edit `android/app/build.gradle.kts` and update `ndkVersion` or rely on the Gradle plugin to download the configured side-by-side NDK.
- Keep secrets out of the repo: use `.env` locally (not committed) or CI secret storage.


## Configuration & Environment

The app reads configuration from `lib/config/app_config.dart` and environment values (for local dev you can use a `.env` file). Typical settings:

- `AZURE_STORAGE_ACCOUNT` - storage account name
- `AZURE_STORAGE_KEY` - account key or SAS token
- `AZURE_CONTAINER` - default container name

Add them to a `.env` at the project root (not committed) or set them in your CI environment.

## Development

Install dependencies and run locally:

```bash
flutter pub get
flutter run -d <device-id>
```

Build release:

```bash
flutter build apk --release
```

Testing:

```bash
flutter test
```

Notes for Android development:
- Use the correct device identifier from `flutter devices` (e.g. `R9YR90F5V6Y`).
- Use the Gradle wrapper in the `android` folder: on Windows run `android\\gradlew.bat assembleDebug`.

## Troubleshooting

- NDK errors (missing `source.properties`): delete the malformed NDK folder and run a clean build so Gradle downloads it again.

	On Windows (PowerShell):

	```powershell
	Remove-Item -Recurse -Force "C:\Users\<your-user>\AppData\Local\Android\sdk\ndk\28.2.13676358"
	flutter clean
	cd android
	.\gradlew.bat clean
	cd ..
	flutter run -d <device-id>
	```

- If `gradle` is not found, use the wrapper `gradlew`/`gradlew.bat` located in the `android` directory.

## Contributing

- Fork the repo and open a pull request.
- Keep changes focused; include tests for new logic where applicable.

## License

This project is released under the MIT License — see the `LICENSE` file for details.

## Sample Commands

Quick commands you will use frequently while developing or debugging:

```bash
# Install dependencies
flutter pub get

# List devices
flutter devices

# Run on a specific device (use id from `flutter devices`)
flutter run -d R9YR90F5V6Y

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Clean build artifacts
flutter clean

# Use Gradle wrapper for Android-specific tasks (Windows example)
cd android
.\gradlew.bat assembleDebug
cd ..

# Install an APK to a connected device
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
