import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';

class FileUploadDialog extends StatefulWidget {
  const FileUploadDialog({super.key});

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _fileNameController = TextEditingController();
  String? _selectedCategory;
  bool _isPrivate = false;
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadError;
  late AnimationController _progressController;

  final List<_CategoryOption> _categories = [
    _CategoryOption('video', 'Video', Icons.play_circle_rounded, const Color(0xFFFF6B9D)),
    _CategoryOption('image', 'Image', Icons.image_rounded, const Color(0xFF4ECDC4)),
    _CategoryOption('music', 'Music', Icons.music_note_rounded, const Color(0xFFFFD93D)),
    _CategoryOption('document', 'Document', Icons.description_rounded, const Color(0xFF6BCB77)),
    _CategoryOption('other', 'Other', Icons.extension_rounded, const Color(0xFFFF9A3C)),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        if (_fileNameController.text.isEmpty) {
          _fileNameController.text = _pickedFile!.name;
        }
        // Auto-detect category
        final ext = _pickedFile!.extension?.toLowerCase() ?? '';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext)) {
          _selectedCategory = 'image';
        } else if (['mp4', 'avi', 'mov', 'mkv', 'webm'].contains(ext)) {
          _selectedCategory = 'video';
        } else if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(ext)) {
          _selectedCategory = 'music';
        } else if (['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'].contains(ext)) {
          _selectedCategory = 'document';
        } else {
          _selectedCategory = 'other';
        }
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null) {
      setState(() => _uploadError = 'Please select a file');
      return;
    }
    if (_fileNameController.text.isEmpty) {
      setState(() => _uploadError = 'Please enter a file name');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _uploadError = 'Please select a category');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
      _uploadProgress = 0;
    });
    _progressController.repeat();

    try {
      final String fileName = _fileNameController.text;
      final String category = _selectedCategory!;

      if (kIsWeb) {
        await Provider.of<FileProvider>(context, listen: false)
            .uploadFileFromBytes(_pickedFile!.bytes!, fileName, category, _isPrivate);
      } else {
        await Provider.of<FileProvider>(context, listen: false)
            .uploadFile(File(_pickedFile!.path!), fileName, category, _isPrivate);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Upload failed: $e';
        _isUploading = false;
      });
      _progressController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A2A45)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary.withOpacity(0.3), cs.secondary.withOpacity(0.2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.cloud_upload_rounded, color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload File',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      Text('Add a file to Azure Blob Storage',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: cs.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2A45)),
            // Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drop zone
                  GestureDetector(
                    onTap: _isUploading ? null : _pickFile,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 110,
                      decoration: BoxDecoration(
                        color: _pickedFile != null
                            ? cs.primary.withOpacity(0.06)
                            : const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _pickedFile != null
                              ? cs.primary.withOpacity(0.4)
                              : const Color(0xFF2A2A45),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: _pickedFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_rounded,
                                    size: 28, color: cs.onSurface.withOpacity(0.3)),
                                const SizedBox(height: 8),
                                Text('Click to select a file',
                                    style: TextStyle(
                                        color: cs.onSurface.withOpacity(0.45),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('Any file type supported',
                                    style: TextStyle(
                                        color: cs.onSurface.withOpacity(0.25),
                                        fontSize: 11)),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: cs.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child:
                                        Icon(Icons.insert_drive_file_rounded, color: cs.primary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _pickedFile!.name,
                                          style: TextStyle(
                                              color: cs.onSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                              color: cs.onSurface.withOpacity(0.4),
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isUploading ? null : _pickFile,
                                    child: Text('Change',
                                        style: TextStyle(
                                            color: cs.primary, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // File name field
                  _Label('File Name'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _fileNameController,
                    enabled: !_isUploading,
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                    decoration: _inputDeco(cs, 'e.g. my-photo.jpg'),
                  ),
                  const SizedBox(height: 16),
                  // Category grid
                  _Label('Category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat.key;
                      return GestureDetector(
                        onTap: _isUploading
                            ? null
                            : () => setState(() => _selectedCategory = cat.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.color.withOpacity(0.15)
                                : const Color(0xFF0F0F1A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? cat.color.withOpacity(0.5)
                                  : const Color(0xFF2A2A45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon,
                                  size: 14,
                                  color: selected
                                      ? cat.color
                                      : cs.onSurface.withOpacity(0.4)),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? cat.color
                                      : cs.onSurface.withOpacity(0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Private toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isPrivate
                          ? const Color(0xFFB8B4FF).withOpacity(0.08)
                          : const Color(0xFF0F0F1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isPrivate
                            ? const Color(0xFFB8B4FF).withOpacity(0.3)
                            : const Color(0xFF2A2A45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
                          size: 18,
                          color: _isPrivate
                              ? const Color(0xFFB8B4FF)
                              : cs.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mark as Private',
                                  style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text('File will require password to access',
                                  style: TextStyle(
                                      color: cs.onSurface.withOpacity(0.35),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPrivate,
                          onChanged: _isUploading
                              ? null
                              : (v) => setState(() => _isPrivate = v),
                          activeColor: const Color(0xFFB8B4FF),
                        ),
                      ],
                    ),
                  ),
                  // Error
                  if (_uploadError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: cs.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_uploadError!,
                                style:
                                    TextStyle(color: cs.error, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Progress bar
            if (_isUploading)
              LinearProgressIndicator(
                backgroundColor: const Color(0xFF2A2A45),
                color: cs.primary,
                minHeight: 2,
              ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF2A2A45)),
                        ),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.6))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isUploading
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)]),
                        color: _isUploading ? const Color(0xFF2A2A45) : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isUploading
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Upload File',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(ColorScheme cs, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF0F0F1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _CategoryOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryOption(this.key, this.label, this.icon, this.color);
}
