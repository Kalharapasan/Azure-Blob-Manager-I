import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';

class FileList extends StatelessWidget {
  final String category;
  final bool showPrivate;

  const FileList({Key? key, required this.category, required this.showPrivate})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    if (fileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fileProvider.error != null) {
      return Center(
        child: Text('Error: ${fileProvider.error}'),
      );
    }

    return ListView.builder(
      itemCount: displayedFiles.length,
      itemBuilder: (context, index) {
        final file = displayedFiles[index];
        return FileItemWidget(file: file);
      },
    );
  }
}

class FileItemWidget extends StatelessWidget {
  final FileItem file;

  const FileItemWidget({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: _getFileIcon(file.category),
        title: Text(file.name),
        subtitle: Text(
          'Size: ${(file.size / 1024).toStringAsFixed(2)} KB\n'
          'Uploaded: ${file.uploadedAt.toLocal()}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              await _deleteFile(context, file);
            } else if (value == 'download') {
              await _downloadFile(context, file);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
        onTap: () => _openFile(context, file),
      ),
    );
  }

  Widget _getFileIcon(String category) {
    switch (category) {
      case 'video':
        return const Icon(Icons.videocam, color: Colors.red);
      case 'image':
        return const Icon(Icons.image, color: Colors.blue);
      case 'music':
        return const Icon(Icons.music_note, color: Colors.green);
      case 'document':
        return const Icon(Icons.description, color: Colors.orange);
      default:
        return const Icon(Icons.file_present, color: Colors.grey);
    }
  }

  Future<void> _deleteFile(BuildContext context, FileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final fileProvider = Provider.of<FileProvider>(context, listen: false);
        await fileProvider.deleteFile(
          '${file.category}/${file.name}',
          file.category,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete file: $e')));
      }
    }
  }

  Future<void> _downloadFile(BuildContext context, FileItem file) async {
    try {
      final fileProvider = Provider.of<FileProvider>(context, listen: false);
      await fileProvider.downloadFile('${file.category}/${file.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File downloaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download file: $e')));
    }
  }

  Future<void> _openFile(BuildContext context, FileItem file) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: SingleChildScrollView(child: _getFilePreview(file)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _getFilePreview(FileItem file) {
    switch (file.category) {
      case 'image':
        return Image.network(file.url);
      case 'video':
        return const Text(
          'Video preview not available in dialog. Tap to download and play.',
        );
      case 'music':
        return const Text(
          'Audio preview not available in dialog. Tap to download and play.',
        );
      case 'document':
        return const Text(
          'Document preview not available. Tap to download and open.',
        );
      default:
        return const Text('Preview not available for this file type.');
    }
  }
}
