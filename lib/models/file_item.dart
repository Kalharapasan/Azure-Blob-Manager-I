class FileItem {
  final String name;
  final String url;
  final int size;
  final String category;
  final DateTime uploadedAt;
  final bool isPrivate;

  FileItem({
    required this.name,
    required this.url,
    required this.size,
    required this.category,
    required this.uploadedAt,
    required this.isPrivate,
  });
}
