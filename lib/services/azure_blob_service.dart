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
    final String configuredUrl = AppConfig.azureStorageUrl.trim();
    final Uri? parsedUrl =
        configuredUrl.isEmpty ? null : Uri.tryParse(configuredUrl);

    if (parsedUrl != null &&
        parsedUrl.host.contains('.blob.core.windows.net') &&
        parsedUrl.pathSegments.isNotEmpty) {
      _accountName = parsedUrl.host.split('.').first;
      _containerName = parsedUrl.pathSegments.first;
      _sasToken = parsedUrl.query.trim().replaceFirst(RegExp(r'^\?'), '');
    } else {
      _accountName = AppConfig.azureStorageAccount;
      _containerName = AppConfig.azureStorageContainer;
      _sasToken = AppConfig.azureSaSToken;
    }

    _baseUrl = 'https://$_accountName.blob.core.windows.net/$_containerName';
  }

  Uri _buildUrl(String baseUrl, [Map<String, String> extraQuery = const {}]) {
    final String sanitizedBase = baseUrl.split('?').first;
    final StringBuffer query = StringBuffer(_sasToken);

    if (extraQuery.isNotEmpty) {
      for (final MapEntry<String, String> entry in extraQuery.entries) {
        if (query.isNotEmpty) {
          query.write('&');
        }
        query.write('${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}');
      }
    }

    return Uri.parse('$sanitizedBase?${query.toString()}');
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

      final Uri url = _buildUrl('$_baseUrl/$blobPath');
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

  Future<String> uploadFileFromBytes(
    List<int> fileBytes,
    String fileName,
    String category,
    bool isPrivate,
  ) async {
    try {
      final String blobPath = isPrivate
          ? 'private/$category/$fileName'
          : '$category/$fileName';

      final Uri url = _buildUrl('$_baseUrl/$blobPath');
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
      final Uri url = _buildUrl('$_baseUrl/$blobPath');
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
      final Uri url = _buildUrl('$_baseUrl/$blobPath');

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
      final Uri url = _buildUrl(_baseUrl, {
        'restype': 'container',
        'comp': 'list',
      });

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
              
              final int contentLengthStart = line.indexOf('<Content-Length>');
              final int contentLengthEnd = line.indexOf('</Content-Length>');
              int contentLength = 0;
              if (contentLengthStart > 0 && contentLengthEnd > contentLengthStart) {
                contentLength = int.tryParse(line.substring(contentLengthStart + 16, contentLengthEnd)) ?? 0;
              }

              final int lastModStart = line.indexOf('<Last-Modified>');
              final int lastModEnd = line.indexOf('</Last-Modified>');
              DateTime lastModified = DateTime.now();
              if (lastModStart > 0 && lastModEnd > lastModStart) {
                lastModified = _parseDate(line.substring(lastModStart + 15, lastModEnd));
              }

              final FileItem fileItem = FileItem(
                name: fileName,
                url:
                    'https://$_accountName.blob.core.windows.net/$_containerName/$blobName',
                size: contentLength,
                category: category,
                uploadedAt: lastModified,
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

      final Uri url = _buildUrl(_baseUrl, {
        'restype': 'container',
        'comp': 'list',
      });

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

            final int contentLengthStart = line.indexOf('<Content-Length>');
            final int contentLengthEnd = line.indexOf('</Content-Length>');
            int contentLength = 0;
            if (contentLengthStart > 0 && contentLengthEnd > contentLengthStart) {
              contentLength = int.tryParse(line.substring(contentLengthStart + 16, contentLengthEnd)) ?? 0;
            }

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
      final Uri url = _buildUrl('$_baseUrl/$blobName', {'comp': 'properties'});
      final http.Response response = await http.head(url);
      if (response.statusCode == 200) {
        return {
          'contentLength':
              int.tryParse(response.headers['content-length'] ?? '0') ?? 0,
          'lastModified': _parseDate(response.headers['last-modified']),
        };
      } else {
        return {'contentLength': 0, 'lastModified': DateTime.now()};
      }
    } catch (e) {
      return {'contentLength': 0, 'lastModified': DateTime.now()};
    }
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString).toLocal();
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
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
