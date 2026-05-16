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
    await dotenv.load(fileName: ".env");
  }
}
