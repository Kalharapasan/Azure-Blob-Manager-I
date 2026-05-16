class FileItem {
  final String name;
  final String blobName;
  final String url;
  final int size;
  final String category;
  final DateTime uploadedAt;
  final bool isPrivate;

  FileItem({
    required this.name,
    required this.blobName,
    required this.url,
    required this.size,
    required this.category,
    required this.uploadedAt,
    required this.isPrivate,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      blobName: json['blobName'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
      category: json['category'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      isPrivate: json['isPrivate'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'blobName': blobName,
      'url': url,
      'size': size,
      'category': category,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isPrivate': isPrivate,
    };
  }
}
