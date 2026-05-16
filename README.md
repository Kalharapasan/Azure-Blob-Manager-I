# Azure Blob Manager (Flutter)

A lightweight Flutter app to browse, upload, and manage files stored in Azure Blob Storage.

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

