import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get azureStorageUrl => dotenv.env['AZURE_STORAGE_URL'] ?? '';
  static String get azureStorageAccount =>
      dotenv.env['AZURE_STORAGE_ACCOUNT'] ?? '';
  static String get azureStorageContainer =>
      dotenv.env['AZURE_STORAGE_CONTAINER'] ?? '';
  static String get azureSaSToken {
    final String token = dotenv.env['AZURE_SAS_TOKEN'] ?? '';
    return token.trim().replaceFirst(RegExp(r'^\?'), '');
  }
  static String get appName => dotenv.env['APP_NAME'] ?? 'Azure Blob Manager';
  static String get privateSectionPassword =>
      dotenv.env['PRIVATE_SECTION_PASSWORD'] ?? '';

  static Future<void> load() async {
    // We try multiple common paths to be safe across different platforms and configurations
    final List<String> pathsToTry = [
      'assets/env/app_env',
      '.env',
      'assets/.env',
    ];

    bool loaded = false;
    for (final path in pathsToTry) {
      try {
        await dotenv.load(fileName: path);
        print('Successfully loaded environment variables from $path');
        loaded = true;
        break;
      } catch (e) {
        // Only print if we've tried everything and failed, or in debug mode
        print('Attempted to load environment from $path but failed: $e');
      }
    }

    if (!loaded) {
      print("Warning: Failed to load environment variables from any source. "
          "If you recently added these files, you MUST completely stop and restart the Flutter app (hot reload is not enough). "
          "Also ensure that the files are listed in pubspec.yaml.");
    }
  }
}
