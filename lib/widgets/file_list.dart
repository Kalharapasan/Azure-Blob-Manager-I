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

  }

  Future<void> _deleteFile(BuildContext context, FileItem file) async {

  }

  if (confirmed == true) {

    try {

      final fileProvider = Provider.of<FileProvider>(context, listen: false);
        await fileProvider.deleteFile(
            '${file.category}/${file.name}', file.category);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete file: $e')),
      );
    }

  }

  Future<void> _downloadFile(BuildContext context, FileItem file) async {


  }

  Future<void> _openFile(BuildContext context, FileItem file) async {


  }

  Widget _getFilePreview(FileItem file) {


  }

}
