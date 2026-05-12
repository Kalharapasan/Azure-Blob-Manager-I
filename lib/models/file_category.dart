enum FileCategory { video, image, music, document, other }

extension FileCategoryExtension on FileCategory {
  String get displayName {
    switch (this) {
      case FileCategory.video:
        return 'Video';
      case FileCategory.image:
        return 'Image';
      case FileCategory.music:
        return 'Music';
      case FileCategory.document:
        return 'Document';
      case FileCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case FileCategory.video:
        return '🎬';
      case FileCategory.image:
        return '🖼️';
      case FileCategory.music:
        return '🎵';
      case FileCategory.document:
        return '📄';
      case FileCategory.other:
        return '📁';
    }
  }
}
