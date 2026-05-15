import 'package:flutter/material.dart';

class CategorySidebar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'all':
        return Icons.storage;
      case 'video':
        return Icons.videocam;
      case 'image':
        return Icons.image;
      case 'music':
        return Icons.music_note;
      case 'document':
        return Icons.description;
      case 'other':
        return Icons.folder;
      default:
        return Icons.file_present;
    }
  }
}
