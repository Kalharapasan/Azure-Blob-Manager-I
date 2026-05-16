# Azure Blob Manager (Flutter)

A lightweight Flutter app to browse, upload, and manage files stored in Azure Blob Storage.

## Screenshots

The app screenshots (tap to enlarge):

| Desktop / Tablet | Desktop / Tablet | Desktop / Tablet |
|---|---|---|
| <img src="https://github.com/user-attachments/assets/803ccf06-9e37-4a7b-a492-7d8a7287b838" alt="Capture3" width="360"/> | <img src="https://github.com/user-attachments/assets/f8865f64-eaad-41d1-890a-4107db77cf7e" alt="Capture2" width="360"/> | <img src="https://github.com/user-attachments/assets/089c2e04-bf31-49f7-b8ae-0e6be77ebb19" alt="Capture" width="360"/> |

| Mobile (portrait) | Mobile (portrait) | Mobile (portrait) |
|---|---|---|
| <img src="https://github.com/user-attachments/assets/bfcb394f-8baf-4e1d-ab72-25d0ea761d81" alt="Phone1" width="200"/> | <img src="https://github.com/user-attachments/assets/70407243-2ed5-4b25-a14a-c2d44ba2a622" alt="Phone2" width="200"/> | <img src="https://github.com/user-attachments/assets/c55134ab-d475-469a-81f8-ad745edb28b4" alt="Phone3" width="200"/> |

| Mobile (portrait) | Mobile (portrait) |
|---|---|
| <img src="https://github.com/user-attachments/assets/e1c20dea-a87e-42ed-8165-f156220b69b0" alt="Phone4" width="200"/> | <img src="https://github.com/user-attachments/assets/13e66b58-fd34-4cb4-aac4-39951fb340eb" alt="Phone5" width="200"/> |

| Mobile (portrait) |
|---|
| <img src="https://github.com/user-attachments/assets/496676bc-286d-4db5-9e5e-0e79c3a0fa9a" alt="Phone6" width="200"/> |


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
This project is released under the MIT License — see the [LICENSE](./LICENSE) file for details.

---

## Project Overview

`Azure Blob Manager` is a cross platform Flutter application that provides a simple UI for interacting with Azure Blob Storage. It is intended for small teams and personal projects that need quick file browsing, uploading, and basic analytics.

Key goals:
- Minimal, responsive UI for mobile and desktop
- Simple authentication/configuration via environment variables
- Safe file operations (upload/download/delete) with confirmations

## Architecture

- UI: Flutter widgets under `lib/widgets` and `lib/screens`.
- State & logic: Provider-based state management in `lib/providers`.
- Services: Azure API interactions implemented in `lib/services/azure_blob_service.dart`.
- Models: Data models in `lib/models`.

## Additional Details

### Detailed Features
- Container browser: list containers and switch between them.
- File list: paginated listing with metadata (name, size, last modified).
- File preview: quick preview for common file types (images, text).
- Uploads: single and multi-file uploads with progress and resumable support where possible.
- Delete + restore: delete confirmation and soft-delete awareness if the storage account supports it.
- Search & filter: search by filename and filter by file type or size.
- Usage charts: basic storage usage and file counts per container.

### How it works (high level)
1. App initializes and loads configuration from `lib/config/app_config.dart` (env or CI-provided secrets).
2. `file_provider` fetches container and blob lists via `azure_blob_service`.
3. Uploads use a direct PUT or SDK client call; progress is streamed back to the UI component.
4. Downloads use signed URLs or SDK streams depending on configuration.
5. All network calls are handled asynchronously with error handling and retries for transient errors.

### Azure integration details
- Uses Azure Storage REST APIs or the Azure Storage SDK for Dart (if available). Implementation details are in `lib/services/azure_blob_service.dart`.
- Supports using either an account key, shared access signature (SAS), or token-based auth. Prefer SAS or token-based auth in production.
- When possible, the app requests short-lived SAS tokens from a backend service (not included) to avoid embedding permanent keys in the client.

### Security
- Do NOT commit secrets (account keys, SAS tokens) to version control. Use `.env` files locally and CI secret stores in pipelines.
- Prefer server-side token issuance for production deployments.
- Use HTTPS endpoints for any backend or token exchange.

### Configuration examples
Create a `.env` file at the project root with the following example values (do NOT commit):

```
AZURE_STORAGE_ACCOUNT=your_account_name
AZURE_STORAGE_KEY=your_account_key_or_blank_if_using_sas
AZURE_SAS_TOKEN=?sv=...
AZURE_CONTAINER=my-container
```

`lib/config/app_config.dart` reads these variables — modify it if your environment uses a different secret mechanism.

### Roadmap
- Add background upload support and paused/resume functionality.
- Add server-side token generator example in `examples/token-service/`.
- Improve file previews for more formats (PDF, Office files) via embedded viewers.

### Known issues
- Large file uploads may fail on unreliable networks; consider chunked uploads or managed upload APIs.
- Android NDK side-by-side downloads can fail if local SDK is corrupted — see Troubleshooting above.

### Contact
If you need help, open an issue on the repository or contact the maintainer at the email address in the project metadata.


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

This project is released under the MIT License — see the [LICENSE](./LICENSE) file for details.

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
