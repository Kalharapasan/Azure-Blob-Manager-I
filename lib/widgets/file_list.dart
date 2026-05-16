import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/file_provider.dart';
import '../models/file_item.dart';
import 'package:url_launcher/url_launcher.dart';

class FileList extends StatelessWidget {
  final String category;
  final String searchQuery;
  final bool isGridView;

  const FileList({
    super.key,
    required this.category,
    this.searchQuery = '',
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    if (fileProvider.isLoading) {
      return const _LoadingState();
    }

    if (fileProvider.error != null) {
      return _ErrorState(error: fileProvider.error!);
    }

    List<FileItem> files = fileProvider.files;

    // Filter by category
    if (category == 'private') {
      files = files.where((f) => f.isPrivate).toList();
    } else if (category != 'all') {
      files = files.where((f) => f.category == category && !f.isPrivate).toList();
    } else {
      files = files.where((f) => !f.isPrivate).toList();
    }

    // Filter by search
    if (searchQuery.isNotEmpty) {
      files = files
          .where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (files.isEmpty) {
      return _EmptyState(category: category, hasSearch: searchQuery.isNotEmpty);
    }

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) => _FileGridCard(file: files[index], index: index),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: files.length,
      itemBuilder: (context, index) => _FileListCard(file: files[index], index: index),
    );
  }
}

// ─── Category accent colors ──────────────────────────────────────────────────

Color _categoryColor(String category) {
  switch (category) {
    case 'image': return const Color(0xFF4ECDC4);
    case 'video': return const Color(0xFFFF6B9D);
    case 'music': return const Color(0xFFFFD93D);
    case 'document': return const Color(0xFF6BCB77);
    default: return const Color(0xFFFF9A3C);
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'image': return Icons.image_rounded;
    case 'video': return Icons.play_circle_rounded;
    case 'music': return Icons.music_note_rounded;
    case 'document': return Icons.description_rounded;
    default: return Icons.extension_rounded;
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
}

// ─── List Card ───────────────────────────────────────────────────────────────

class _FileListCard extends StatefulWidget {
  final FileItem file;
  final int index;

  const _FileListCard({required this.file, required this.index});

  @override
  State<_FileListCard> createState() => _FileListCardState();
}

class _FileListCardState extends State<_FileListCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 40),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(widget.file.category);
    final f = widget.file;

    return FadeTransition(
      opacity: _fadeIn,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF1E1E38) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? color.withOpacity(0.3) : const Color(0xFF2A2A45),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16)]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // File type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon(f.category), color: color, size: 22),
                ),
                const SizedBox(width: 14),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _Chip(label: f.category, color: color),
                          const SizedBox(width: 6),
                          _Chip(label: _formatSize(f.size), color: Colors.white30),
                          if (f.isPrivate) ...[
                            const SizedBox(width: 6),
                            _Chip(
                              label: 'Private',
                              color: const Color(0xFFB8B4FF),
                              icon: Icons.lock_rounded,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Date
                Text(
                  _formatDate(f.uploadedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.35),
                  ),
                ),
                const SizedBox(width: 12),
                // Actions
                _FileActions(file: f),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

// ─── Grid Card ───────────────────────────────────────────────────────────────

class _FileGridCard extends StatefulWidget {
  final FileItem file;
  final int index;

  const _FileGridCard({required this.file, required this.index});

  @override
  State<_FileGridCard> createState() => _FileGridCardState();
}

class _FileGridCardState extends State<_FileGridCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(widget.file.category);
    final f = widget.file;

    return FadeTransition(
      opacity: _fadeIn,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF1E1E38) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? color.withOpacity(0.4) : const Color(0xFF2A2A45),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 20)]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_categoryIcon(f.category), color: color, size: 26),
                    ),
                    const Spacer(),
                    _FileActions(file: f),
                  ],
                ),
                const Spacer(),
                Text(
                  f.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(label: _formatSize(f.size), color: Colors.white30),
                    if (f.isPrivate) ...[
                      const SizedBox(width: 6),
                      _Chip(label: 'Private', color: const Color(0xFFB8B4FF), icon: Icons.lock_rounded),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── File Actions ─────────────────────────────────────────────────────────────

class _FileActions extends StatelessWidget {
  final FileItem file;
  const _FileActions({required this.file});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') _delete(context);
        if (value == 'download') _download(context);
        if (value == 'preview') _preview(context);
      },
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2A2A45)),
      ),
      itemBuilder: (_) => [
        _menuItem('preview', 'Preview', Icons.visibility_rounded),
        _menuItem('download', 'Download', Icons.download_rounded),
        _menuItem('delete', 'Delete', Icons.delete_rounded, isDestructive: true),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.white54),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData icon,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isDestructive ? const Color(0xFFFF5F7E) : Colors.white54),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? const Color(0xFFFF5F7E) : const Color(0xFFE8E8F0),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDeleteDialog(fileName: file.name),
    );
    if (confirmed == true && context.mounted) {
      try {
        await Provider.of<FileProvider>(context, listen: false)
            .deleteFile(file.blobName, file.category);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _download(BuildContext context) async {
    try {
      if (kIsWeb) {
        final Uri url = Uri.parse(file.url);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download started in new tab')),
            );
          }
          return;
        } else {
          throw 'Could not open download link';
        }
      }

      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading...'), duration: Duration(seconds: 1)),
      );

      final bytes = await Provider.of<FileProvider>(context, listen: false)
          .downloadFile(file.blobName);
      
      String? outputPath;
      // We check kIsWeb first to avoid Platform._operatingSystem crash on web
      final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
        try {
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save File',
            fileName: file.name,
          );
        } catch (e) {
          debugPrint('saveFile failed: $e');
        }
      }

      // If saveFile failed or we are on mobile, try getDirectoryPath
      if (outputPath == null) {
        try {
          final directory = await FilePicker.platform.getDirectoryPath();
          if (directory != null) {
            outputPath = '$directory/${file.name}';
          }
        } catch (e) {
          debugPrint('getDirectoryPath failed: $e');
        }
      }

      // Final fallback to platform-specific storage
      if (outputPath == null) {
        final dir = Platform.isAndroid
            ? await getExternalStorageDirectory()
            : await getApplicationDocumentsDirectory();
        if (dir != null) {
          outputPath = '${dir.path}/${file.name}';
        }
      }

      if (outputPath != null) {
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved: ${outputPath.split('/').last}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void _preview(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _FilePreviewDialog(file: file),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confirm Delete ───────────────────────────────────────────────────────────

class _ConfirmDeleteDialog extends StatelessWidget {
  final String fileName;
  const _ConfirmDeleteDialog({required this.fileName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Delete File',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete "$fileName"? This cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.55)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF2A2A45)),
                      ),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Preview Dialog ───────────────────────────────────────────────────────────

class _FilePreviewDialog extends StatelessWidget {
  final FileItem file;
  const _FilePreviewDialog({required this.file});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(file.category);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon(file.category), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatSize(file.size),
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurface.withOpacity(0.45)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon:
                      Icon(Icons.close_rounded, color: cs.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A45)),
              ),
              child: file.category == 'image'
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        file.url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _previewPlaceholder(context),
                      ),
                    )
                  : _previewPlaceholder(context),
            ),
            const SizedBox(height: 16),
            // Metadata
            _MetaRow('Category', file.category),
            _MetaRow('Size', _formatSize(file.size)),
            _MetaRow('Uploaded', file.uploadedAt.toLocal().toString().split('.').first),
            _MetaRow('Private', file.isPrivate ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _previewPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(file.category);
    return Column(
      children: [
        Icon(_categoryIcon(file.category), color: color, size: 48),
        const SizedBox(height: 12),
        Text(
          'Preview not available for this file type',
          style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 13),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.75),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Loading files…',
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.45), fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: cs.error, size: 48),
          const SizedBox(height: 12),
          Text('Failed to load files',
              style: TextStyle(
                  color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(error,
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.45), fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String category;
  final bool hasSearch;
  const _EmptyState({required this.category, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearch ? Icons.search_off_rounded : Icons.folder_open_rounded,
            size: 56,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No files match your search' : 'No files in this category',
            style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'Upload files using the button below',
            style:
                TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
