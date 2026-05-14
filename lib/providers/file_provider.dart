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

  

}