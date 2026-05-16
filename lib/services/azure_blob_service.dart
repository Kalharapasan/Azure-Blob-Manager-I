import 'dart:io';
import 'dart:typed_data';
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

  Uri _buildUrl({String? blobPath, Map<String, String> extraQuery = const {}}) {
    // Ensure baseUrl doesn't end with slash if blobPath starts with one
    String base = _baseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    
    final List<String> pathSegments = Uri.parse(base).pathSegments.toList();
    if (blobPath != null && blobPath.isNotEmpty) {
      // Handle both forward and backward slashes, and filter out empty segments
      pathSegments.addAll(blobPath.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty));
    }

    final query = <String, dynamic>{};
    // Parse existing SAS token parameters
    // Handle case where sasToken might already have a leading ?
    String token = _sasToken;
    if (token.startsWith('?')) token = token.substring(1);
    
    final sasUri = Uri.parse('?$token');
    query.addAll(sasUri.queryParameters);
    query.addAll(extraQuery);

    return Uri(
      scheme: 'https',
      host: '$_accountName.blob.core.windows.net',
      pathSegments: pathSegments,
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<String> _putBlob(Uri url, List<int> fileBytes, String fileName) async {
    // Use http.Client with explicit Content-Length; Azure Blob rejects
    // chunked-transfer-encoded PUT requests (which http.put() sends when the
    // body length is unknown at the header-writing stage).
    final client = http.Client();
    try {
      final request = http.Request('PUT', url);
      request.headers['x-ms-blob-type'] = 'BlockBlob';
      request.headers['Content-Type'] = _getContentType(fileName);
      request.headers['Content-Length'] = fileBytes.length.toString();
      request.bodyBytes = Uint8List.fromList(fileBytes);

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.statusCode.toString();
      } else {
        throw Exception(
          'Azure rejected upload: ${response.statusCode} - ${response.body}',
        );
      }
    } finally {
      client.close();
    }
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

      final Uri url = _buildUrl(blobPath: blobPath);
      final List<int> fileBytes = await file.readAsBytes();
      await _putBlob(url, fileBytes, fileName);
      return _buildUrl(blobPath: blobPath).toString();
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

      final Uri url = _buildUrl(blobPath: blobPath);
      await _putBlob(url, fileBytes, fileName);
      return _buildUrl(blobPath: blobPath).toString();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<List<int>> downloadFile(String blobPath) async {
    try {
      final Uri url = _buildUrl(blobPath: blobPath);
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
      final Uri url = _buildUrl(blobPath: blobPath);

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
      final Uri url = _buildUrl(extraQuery: {
        'restype': 'container',
        'comp': 'list',
      });

      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final String responseBody = response.body;

        // More robust XML parsing using RegExp
        final blobRegex = RegExp(r'<Blob>(.*?)</Blob>', dotAll: true);
        final nameRegex = RegExp(r'<Name>(.*?)</Name>');
        final lengthRegex = RegExp(r'<Content-Length>(.*?)</Content-Length>');
        final lastModRegex = RegExp(r'<Last-Modified>(.*?)</Last-Modified>');

        final matches = blobRegex.allMatches(responseBody);

        for (final match in matches) {
          final blobXml = match.group(1) ?? '';
          
          final nameMatch = nameRegex.firstMatch(blobXml);
          if (nameMatch == null) continue;
          
          final String blobName = nameMatch.group(1) ?? '';
          
          bool isMatch = false;
          String fileCategory = 'other';
          String fileName = blobName;
          bool isPrivate = blobName.startsWith('private/');

          if (category == 'all') {
            isMatch = true;
            final List<String> pathParts = blobName.split('/');
            if (pathParts.length >= 2) {
              if (pathParts[0] == 'private' && pathParts.length >= 3) {
                fileCategory = pathParts[1];
                fileName = pathParts.sublist(2).join('/');
              } else {
                fileCategory = pathParts[0];
                fileName = pathParts.sublist(1).join('/');
              }
            } else {
              // If no folders, try to guess from extension
              fileCategory = _guessCategory(blobName);
            }
          } else {
            final String searchPrefix = (category == 'private')
                ? 'private/'
                : '$category/';
            if (blobName.startsWith(searchPrefix)) {
              isMatch = true;
              fileName = blobName.substring(searchPrefix.length);
              fileCategory = category;
            }
          }

          if (isMatch) {
            final lengthMatch = lengthRegex.firstMatch(blobXml);
            final int contentLength = int.tryParse(lengthMatch?.group(1) ?? '0') ?? 0;

            final lastModMatch = lastModRegex.firstMatch(blobXml);
            final DateTime lastModified = _parseDate(lastModMatch?.group(1));

            final FileItem fileItem = FileItem(
              name: fileName,
              blobName: blobName,
              url: _buildUrl(blobPath: blobName).toString(),
              size: contentLength,
              category: fileCategory,
              uploadedAt: lastModified,
              isPrivate: isPrivate,
            );
            files.add(fileItem);
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

  String _guessCategory(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'image';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'm4a':
        return 'music';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
        return 'document';
      default:
        return 'other';
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      Map<String, int> categoryCounts = {};
      Map<String, int> categorySizes = {};
      int totalFiles = 0;
      int totalSize = 0;

      final Uri url = _buildUrl(extraQuery: {
        'restype': 'container',
        'comp': 'list',
      });

      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        
        final blobRegex = RegExp(r'<Blob>(.*?)</Blob>', dotAll: true);
        final nameRegex = RegExp(r'<Name>(.*?)</Name>');
        final lengthRegex = RegExp(r'<Content-Length>(.*?)</Content-Length>');

        final matches = blobRegex.allMatches(responseBody);

        for (final match in matches) {
          final blobXml = match.group(1) ?? '';
          
          final nameMatch = nameRegex.firstMatch(blobXml);
          if (nameMatch == null) continue;
          
          final String blobName = nameMatch.group(1) ?? '';
          final List<String> pathParts = blobName.split('/');
          String category = 'other';

          if (pathParts.length >= 2) {
            if (pathParts[0] == 'private' && pathParts.length >= 3) {
              category = pathParts[1];
            } else {
              category = pathParts[0];
            }
          } else {
            category = _guessCategory(blobName);
          }

          if (!categoryCounts.containsKey(category)) {
            categoryCounts[category] = 0;
            categorySizes[category] = 0;
          }

          final lengthMatch = lengthRegex.firstMatch(blobXml);
          final int contentLength = int.tryParse(lengthMatch?.group(1) ?? '0') ?? 0;

          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
          categorySizes[category] = (categorySizes[category] ?? 0) + contentLength;
          totalFiles++;
          totalSize += contentLength;
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
      // Azure Blob: HEAD <blob-url>?<sas> — no comp=properties needed
      final Uri url = _buildUrl(blobPath: blobName);
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
    if (dateString == null || dateString.isEmpty) return DateTime.now();
    try {
      // Azure returns dates in RFC 1123 format (e.g., "Wed, 21 Oct 2015 07:28:00 GMT")
      // HttpDate.parse handles this format.
      return HttpDate.parse(dateString).toLocal();
    } catch (e) {
      try {
        return DateTime.parse(dateString).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  bool isPrivateCategory(String category) {
    return category == 'private';
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
