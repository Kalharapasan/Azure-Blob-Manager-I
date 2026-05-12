import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get azureStorageAccount =>
      dotenv.env['AZURE_STORAGE_ACCOUNT'] ?? '';
  static String get azureStorageContainer =>
      dotenv.env['AZURE_STORAGE_CONTAINER'] ?? '';
  static String get azureSaSToken => dotenv.env['AZURE_SAS_TOKEN'] ?? '';
  static String get appName => dotenv.env['APP_NAME'] ?? 'Azure Blob Manager';
  static String get privateSectionPassword =>
      dotenv.env['PRIVATE_SECTION_PASSWORD'] ?? '';
}
