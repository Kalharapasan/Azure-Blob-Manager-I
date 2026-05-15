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
    _baseUrl =
        'https://$_accountName.blob.core.windows.net/$_containerName?$_sasToken';
  }

  Future<String> uploadFile(
    File file,
    String fileName,
    String category,
    bool isPrivate,
  ) async {
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
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Return the blob URL
        return 'https://$_accountName.blob.core.windows.net/$_containerName/$blobPath';
      } else {
        throw Exception(
          'Failed to upload file: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<List<int>> downloadFile(String blobPath) async {
    try {
      final Uri url = Uri.parse('$_baseUrl/$blobPath');
      final http.Response response = await http.get(url);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
          'Failed to download file: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  Future<void> deleteFile(String blobPath) async {
    try {
      final Uri url = Uri.parse('$_baseUrl/$blobPath');

      final http.Response response = await http.delete(url);

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 404) {
        // Success (200, 202) or already deleted (404)
        return;
      } else {
        throw Exception(
          'Failed to delete file: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  Future<List<FileItem>> listFiles(String category) async {
    try {
      final List<FileItem> files = [];
      final Uri url = Uri.parse('$_baseUrl&restype=container&comp=list');

      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final String responseBody = response.body;

        final List<String> blobLines = responseBody
            .split('<Name>')
            .skip(1)
            .toList();

        for (final String line in blobLines) {
          final int endIndex = line.indexOf('</Name>');
          if (endIndex > 0) {
            final String blobName = line.substring(0, endIndex);
            final String searchPrefix = isPrivateCategory(category)
                ? 'private/$category/'
                : '$category/';

            if (blobName.startsWith(searchPrefix)) {
              final String fileName = blobName.substring(searchPrefix.length);
              final Map<String, dynamic> properties = await _getBlobProperties(
                blobName,
              );
              final FileItem fileItem = FileItem(
                name: fileName,
                url:
                    'https://$_accountName.blob.core.windows.net/$_containerName/$blobName',
                size: properties['contentLength'] ?? 0,
                category: category,
                uploadedAt: properties['lastModified'] ?? DateTime.now(),
                isPrivate: blobName.startsWith('private/'),
              );
              files.add(fileItem);
            }
          }
        }
      } else {
        throw Exception(
          'Failed to list files: ${response.statusCode} - ${response.body}',
        );
      }

      return files;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      Map<String, int> categoryCounts = {};
      Map<String, int> categorySizes = {};
      int totalFiles = 0;
      int totalSize = 0;

      final Uri url = Uri.parse('$_baseUrl&restype=container&comp=list');

      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        final List<String> blobLines = responseBody
            .split('<Name>')
            .skip(1)
            .toList();

        for (final String line in blobLines) {
          final int endIndex = line.indexOf('</Name>');

          if (endIndex > 0) {
            final String blobName = line.substring(0, endIndex);
            final List<String> pathParts = blobName.split('/');
            String category = 'other';

            if (pathParts.length >= 2) {
              if (pathParts[0] == 'private' && pathParts.length >= 3) {
                category = pathParts[1];
              } else {
                category = pathParts[0];
              }
            }

            if (!categoryCounts.containsKey(category)) {
              categoryCounts[category] = 0;
              categorySizes[category] = 0;
            }

            final Map<String, dynamic> properties = await _getBlobProperties(
              blobName,
            );
            final int contentLength = properties['contentLength'] ?? 0;

            categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
            categorySizes[category] =
                (categorySizes[category] ?? 0) + contentLength;
            totalFiles++;
            totalSize += contentLength;
          }
        }
      } else {
        throw Exception(
          'Failed to get storage stats: ${response.statusCode} - ${response.body}',
        );
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'categoryCounts': categoryCounts,
        'categorySizes': categorySizes,
      };
    } catch (e) {
      throw Exception('Failed to get storage stats: $e');
    }
  }

  Future<Map<String, dynamic>> _getBlobProperties(String blobName) async {
    try {
      final Uri url = Uri.parse('$_baseUrl/$blobName&comp=properties');
      final http.Response response = await http.head(url);
      if (response.statusCode == 200) {
        return {
          'contentLength': int.tryParse(response.headers['content-length'] ?? '0')
              ?? 0,
          'lastModified': _parseDate(response.headers['last-modified']),
        };
      }else{
        return {
          'contentLength': 0,
          'lastModified': DateTime.now(),
        };
      }
    } catch (e) {
      return {
        'contentLength': 0,
        'lastModified': DateTime.now(),
      };
    }
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  bool isPrivateCategory(String category) {
    return false;
  }

  String _getContentType(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      
    }
  }

}
