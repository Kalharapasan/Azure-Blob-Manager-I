import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';

class FileList extends StatelessWidget {
  final String category;
  final bool showPrivate;
  const FileList({super.key});

  const FileList({
    Key? key,
    required this.category,
    required this.showPrivate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {


    return Card(
      
    );
  }
}
