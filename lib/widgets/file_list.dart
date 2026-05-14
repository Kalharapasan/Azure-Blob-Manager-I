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

  const FileItemWidget({
    Key? key,
    required this.file,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}