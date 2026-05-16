import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static bool _isInitialized = false;

  static String _getEnv(String key, [String defaultValue = '']) {
    if (!_isInitialized) return defaultValue;
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  static String get azureStorageUrl => _getEnv('AZURE_STORAGE_URL');
  static String get azureStorageAccount => _getEnv('AZURE_STORAGE_ACCOUNT');
  static String get azureStorageContainer => _getEnv('AZURE_STORAGE_CONTAINER');
  static String get azureSaSToken {
    final String token = _getEnv('AZURE_SAS_TOKEN');
    return token.trim().replaceFirst(RegExp(r'^\?'), '');
  }
  static String get appName => _getEnv('APP_NAME', 'Azure Blob Manager');
  static String get privateSectionPassword => _getEnv('PRIVATE_SECTION_PASSWORD');

  static Future<void> load() async {
    // We try multiple common paths to be safe across different platforms and configurations
    final List<String> pathsToTry = [
      'assets/app.env',
      'assets/env/app_env',
      '.env',
      'assets/.env',
    ];

    for (final path in pathsToTry) {
      try {
        await dotenv.load(fileName: path);
        print('Successfully loaded environment variables from $path');
        _isInitialized = true;
        return;
      } catch (e) {
        print('Attempted to load environment from $path but failed: $e');
      }
    }

    print("Warning: Failed to load environment variables from any source. "
          "The app will use default values. "
          "If you recently added these files, you MUST completely stop and restart the Flutter app.");
  }
}
