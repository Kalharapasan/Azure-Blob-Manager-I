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

  final List<String> _categories = [
    'video',
    'image',
    'music',
    'document',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload File'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File picker
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _pickedFile == null
                    ? 'Select File'
                    : 'Selected: ${_pickedFile!.name}',
              ),
            ),
            const SizedBox(height: 16),
            // File name
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(
                        category[0].toUpperCase() + category.substring(1),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Private toggle
            Row(
              children: [
                Checkbox(
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() {
                      _isPrivate = value ?? false;
                    });
                  },
                ),
                const Text('Mark as Private'),
              ],
            ),
            if (_uploadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _uploadError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
