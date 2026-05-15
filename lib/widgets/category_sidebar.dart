import 'package:flutter/material.dart';

class CategorySidebar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySidebar({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  static const List<String> categories = [
    'all',
    'video',
    'image',
    'music',
    'document',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = selectedCategory == category;
          return ListTile(
            leading: Icon(_getIconForCategory(category)),
            title: Text(
              category[0].toUpperCase() + category.substring(1),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            selected: isSelected,
            onTap: () => onCategorySelected(category),
          );
        },
      ),
    );
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
