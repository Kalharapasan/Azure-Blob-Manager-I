import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';

class PrivateSection extends StatelessWidget {
  const PrivateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Private Section',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(child: PrivateFileList()),
        ],
      ),
    );
  }
}

class PrivateFileList extends StatelessWidget {
  const PrivateFileList({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    final privateFiles = fileProvider.files
        .where((file) => file.isPrivate)
        .toList();

    if (fileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fileProvider.error != null) {
      return Center(child: Text('Error: ${fileProvider.error}'));
    }

    if (privateFiles.isEmpty) {
      return const Center(child: Text('No private files found'));
    }

    return ListView.builder(
      itemCount: privateFiles.length,
      itemBuilder: (context, index) {
        final file = privateFiles[index];
        return PrivateFileItemWidget(file: file);
      },
    );
  }
}

class PrivateFileItemWidget extends StatelessWidget {
  final FileItem file;

  const PrivateFileItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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
}
