import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/file_item.dart';
import '../config/app_config.dart';

class AzureBlobService {
  late final String _accountName;
  late final String _sasToken;
  late final String _containerName;
  late final String _baseUrl;

  AzureBlobService() {
    _accountName = AppConfig.azureStorageAccount;
    _sasToken = AppConfig.azureSaSToken;
    _containerName = AppConfig.azureStorageContainer;
    _baseUrl = 'https://$_accountName.blob.core.windows.net/$_containerName?$_sasToken';
  }

}