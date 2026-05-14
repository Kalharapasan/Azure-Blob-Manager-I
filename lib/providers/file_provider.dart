import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/file_item.dart';
import '../services/azure_blob_service.dart';

class FileProvider extends ChangeNotifier {
  final AzureBlobService _azureBlobService = AzureBlobService();
  List<FileItem> _files = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _storageStats = {};

  List<FileItem> get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get storageStats => _storageStats;

  Future<void> loadFiles(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _files = await _azureBlobService.listFiles(category);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadFile(
    File file,
    String fileName,
    String category,
    bool isPrivate,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String url = await _azureBlobService.uploadFile(
        file,
        fileName,
        category,
        isPrivate,
      );
      await loadFiles(category);
      return url;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFile(String blobPath, String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _azureBlobService.deleteFile(blobPath);
      await loadFiles(category);
    } catch (e) {
      _error = e.toString();
    }finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<int>> downloadFile(String blobPath) {
    return _azureBlobService.downloadFile(blobPath);
  }

  Future<void> loadStorageStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
  }


}
