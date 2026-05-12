import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';

class FileUploadDialog extends StatefulWidget {
  const FileUploadDialog({super.key});

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog> {
  final TextEditingController _fileNameController = TextEditingController();
  String? _selectedCategory;
  bool _isPrivate = false;
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String? _uploadError;

  final List<String> _categories = ['video', 'image', 'music', 'document', 'other'];

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
