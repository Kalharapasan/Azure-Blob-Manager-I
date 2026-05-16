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

    if (fileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fileProvider.error != null) {
      return Center(
        child: Text('Error: ${fileProvider.error}'),
      );
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
