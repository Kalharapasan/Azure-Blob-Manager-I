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

  Future<String> uploadFile(File file, String fileName, String category, bool isPrivate) async {

    try {
      final String blobPath = isPrivate
          ? 'private/$category/$fileName'
          : '$category/$fileName';

      final Uri url = Uri.parse('$_baseUrl/$blobPath');
      final List<int> fileBytes = await file.readAsBytes();
      final http.Response response = await http.put(
        url,
        headers: {
          'x-ms-blob-type': 'BlockBlob',
          'Content-Type': _getContentType(fileName),
        },
        body: fileBytes,
      );
    } catch (e) {
      
    }

  }

}