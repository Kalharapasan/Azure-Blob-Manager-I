import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';

import '../providers/file_provider.dart';
import '../models/file_item.dart';

// ─── Constants & Themes ──────────────────────────────────────────────────────

class AppColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFFEC4899);
  static const accent = Color(0xFF10B981);
  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const card = Color(0xFF1E293B);
  static const border = Color(0xFF334155);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);

  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'image':    return const Color(0xFF38BDF8);
      case 'video':    return const Color(0xFFF472B6);
      case 'music':    return const Color(0xFFFACC15);
      case 'document': return const Color(0xFF4ADE80);
      case 'private':  return const Color(0xFFA78BFA);
      default:         return const Color(0xFF94A3B8);
    }
  }

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'image':    return Icons.image_outlined;
      case 'video':    return Icons.play_circle_outline_rounded;
      case 'music':    return Icons.music_note_outlined;
      case 'document': return Icons.description_outlined;
      case 'private':  return Icons.lock_outline_rounded;
      default:         return Icons.insert_drive_file_outlined;
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
}

String _ext(String name) => p.extension(name).replaceFirst('.', '').toLowerCase();

bool _isTextExt(String ext) => [
      'txt', 'md', 'json', 'xml', 'csv', 'yaml', 'yml', 'js', 'dart', 'py', 'java', 'log'
    ].contains(ext);

bool _isImageExt(String ext) => ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
bool _isVideoExt(String ext) => ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
bool _isAudioExt(String ext) => ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'].contains(ext);
bool _isPdfExt(String ext) => ext == 'pdf';

// ─── Main FileList Widget ─────────────────────────────────────────────────────

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
    final fp = Provider.of<FileProvider>(context);

    if (fp.isLoading) return const _LoadingState();
    if (fp.error != null) return _ErrorState(error: fp.error!);

    List<FileItem> files = fp.files;

    // Filtering
    if (category == 'private') {
      files = files.where((f) => f.isPrivate).toList();
    } else if (category != 'all') {
      files = files.where((f) => f.category == category && !f.isPrivate).toList();
    } else {
      files = files.where((f) => !f.isPrivate).toList();
    }

    if (searchQuery.isNotEmpty) {
      files = files
          .where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    if (files.isEmpty) {
      return _EmptyState(category: category, hasSearch: searchQuery.isNotEmpty);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: isGridView 
        ? _FileGridView(files: files, key: const ValueKey('grid'))
        : _FileListView(files: files, key: const ValueKey('list')),
    );
  }
}

// ─── List & Grid Views ────────────────────────────────────────────────────────

class _FileListView extends StatelessWidget {
  final List<FileItem> files;
  const _FileListView({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: files.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (ctx, i) => _FileItemCard(
        file: files[i], 
        index: i, 
        isGrid: false,
        allFiles: files,
      ),
    );
  }
}

class _FileGridView extends StatelessWidget {
  final List<FileItem> files;
  const _FileGridView({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: files.length,
      itemBuilder: (ctx, i) => _FileItemCard(
        file: files[i], 
        index: i, 
        isGrid: true,
        allFiles: files,
      ),
    );
  }
}

// ─── File Item Card ──────────────────────────────────────────────────────────

class _FileItemCard extends StatefulWidget {
  final FileItem file;
  final int index;
  final bool isGrid;
  final List<FileItem> allFiles;

  const _FileItemCard({
    required this.file, 
    required this.index, 
    required this.isGrid,
    required this.allFiles,
  });

  @override
  State<_FileItemCard> createState() => _FileItemCardState();
}

class _FileItemCardState extends State<_FileItemCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 30).clamp(0, 400)),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _onTap() {
    _MediaViewer.show(context, widget.file, widget.allFiles);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.file;
    final color = AppColors.categoryColor(f.category);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: widget.isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surface.withOpacity(0.8) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? color.withOpacity(0.5) : AppColors.border,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ] : [],
          ),
          child: InkWell(
            onTap: _onTap,
            borderRadius: BorderRadius.circular(20),
            child: widget.isGrid ? _buildGridContent(f, color) : _buildListContent(f, color),
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(FileItem f, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FileThumbnail(file: f, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag(label: _formatSize(f.size), color: Colors.white12),
                    const SizedBox(width: 8),
                    _Tag(label: f.category, color: color.withOpacity(0.2), textColor: color),
                    if (f.isPrivate) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.secondary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _timeAgo(f.uploadedAt),
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          _FileActionsMenu(file: f),
        ],
      ),
    );
  }

  Widget _buildGridContent(FileItem f, Color color) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(child: _FileThumbnail(file: f, size: 70)),
          ),
          const SizedBox(height: 12),
          Text(
            f.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatSize(f.size),
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
              _FileActionsMenu(file: f, isSmall: true),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// ─── Thumbnail Widget ─────────────────────────────────────────────────────────

class _FileThumbnail extends StatelessWidget {
  final FileItem file;
  final double size;

  const _FileThumbnail({required this.file, required this.size});

  @override
  Widget build(BuildContext context) {
    final ext = _ext(file.name);
    final color = AppColors.categoryColor(file.category);

    if (_isImageExt(ext)) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.network(
            file.url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildPlaceholder(color, Icons.image_outlined);
            },
            errorBuilder: (context, error, stackTrace) => 
                _buildPlaceholder(color, Icons.broken_image_outlined),
          ),
        ),
      );
    }

    if (_isVideoExt(ext)) {
      return _buildPlaceholder(color, Icons.play_circle_fill_rounded);
    }
    
    if (_isPdfExt(ext)) {
      return _buildPlaceholder(color, Icons.picture_as_pdf_outlined);
    }

    return _buildPlaceholder(color, AppColors.categoryIcon(file.category));
  }

  Widget _buildPlaceholder(Color color, IconData icon) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(icon, color: color, size: size * 0.45),
    );
  }
}

// ─── Media Viewer (Advanced) ──────────────────────────────────────────────────

class _MediaViewer extends StatefulWidget {
  final FileItem initialFile;
  final List<FileItem> allFiles;

  const _MediaViewer({required this.initialFile, required this.allFiles});

  static void show(BuildContext context, FileItem file, List<FileItem> allFiles) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Media Viewer',
      barrierColor: Colors.black90,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _MediaViewer(initialFile: file, allFiles: allFiles),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutQuad)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<_MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<_MediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late List<FileItem> _swipeableFiles;

  @override
  void initState() {
    super.initState();
    // Only allow swiping between media/docs that are previewable
    _swipeableFiles = widget.allFiles.where((f) {
      final ext = _ext(f.name);
      return _isImageExt(ext) || _isVideoExt(ext) || _isAudioExt(ext) || _isPdfExt(ext) || _isTextExt(ext);
    }).toList();

    _currentIndex = _swipeableFiles.indexOf(widget.initialFile);
    if (_currentIndex == -1) {
      _swipeableFiles = [widget.initialFile];
      _currentIndex = 0;
    }
    
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black54),
            ),
          ),

          // Main Content
          PageView.builder(
            controller: _pageController,
            itemCount: _swipeableFiles.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (context, index) {
              return _ViewerDispatcher(file: _swipeableFiles[index]);
            },
          ),

          // Header
          _buildHeader(),

          // Navigation Arrows (Desktop/Web)
          if (_swipeableFiles.length > 1) ...[
            _buildNavArrow(Icons.chevron_left_rounded, true),
            _buildNavArrow(Icons.chevron_right_rounded, false),
          ],

          // Footer Info
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final f = _swipeableFiles[_currentIndex];
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_formatSize(f.size)} • ${f.category}',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            _ActionIcon(icon: Icons.download_rounded, onTap: () => _download(context, f)),
            _ActionIcon(icon: Icons.share_outlined, onTap: () => _share(f)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_swipeableFiles.length <= 1) return const SizedBox.shrink();
    return Positioned(
      bottom: 40, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            '${_currentIndex + 1} / ${_swipeableFiles.length}',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, bool isLeft) {
    return Positioned(
      left: isLeft ? 20 : null,
      right: isLeft ? null : 20,
      top: 0, bottom: 0,
      child: Center(
        child: InkWell(
          onTap: () {
            _pageController.animateToPage(
              isLeft ? _currentIndex - 1 : _currentIndex + 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.white70, size: 28),
          ),
        ),
      ),
    );
  }

  void _share(FileItem f) {
    Clipboard.setData(ClipboardData(text: f.url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ─── Viewer Dispatcher ────────────────────────────────────────────────────────

class _ViewerDispatcher extends StatelessWidget {
  final FileItem file;
  const _ViewerDispatcher({required this.file});

  @override
  Widget build(BuildContext context) {
    final ext = _ext(file.name);

    if (_isImageExt(ext)) return _ImageViewer(file: file);
    if (_isVideoExt(ext)) return _VideoViewer(file: file);
    if (_isAudioExt(ext)) return _AudioViewer(file: file);
    if (_isPdfExt(ext))   return _PdfViewer(file: file);
    if (_isTextExt(ext))  return _TextViewer(file: file);

    return _UnsupportedViewer(file: file);
  }
}

// ─── Sub-Viewers ──────────────────────────────────────────────────────────────

class _ImageViewer extends StatelessWidget {
  final FileItem file;
  const _ImageViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: NetworkImage(file.url),
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final FileItem file;
  const _VideoViewer({required this.file});
  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.file.url))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true, colors: VideoProgressColors(playedColor: AppColors.secondary)),
            _VideoControls(controller: _controller),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Icon(
                controller.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                color: Colors.white70,
                size: 80,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AudioViewer extends StatefulWidget {
  final FileItem file;
  const _AudioViewer({required this.file});
  @override
  State<_AudioViewer> createState() => _AudioViewerState();
}

class _AudioViewerState extends State<_AudioViewer> {
  final _player = AudioPlayer();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.file.url).then((_) => setState(() => _loading = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.music));
    return Center(
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 40)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: AppColors.music.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note_rounded, color: AppColors.music, size: 60),
            ),
            const SizedBox(height: 32),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _audioBtn(Icons.replay_10_rounded, () => _player.seek(Duration(seconds: (_player.position.inSeconds - 10).clamp(0, 99999)))),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => playing ? _player.pause() : _player.play(),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(color: AppColors.music, shape: BoxShape.circle),
                        child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 36),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _audioBtn(Icons.forward_10_rounded, () => _player.seek(Duration(seconds: (_player.position.inSeconds + 10)))),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur = _player.duration ?? Duration.zero;
                return Column(
                  children: [
                    Slider(
                      value: pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble()),
                      max: dur.inMilliseconds.toDouble(),
                      activeColor: AppColors.music,
                      onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmtDur(pos), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          Text(_fmtDur(dur), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _audioBtn(IconData icon, VoidCallback onTap) => IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white70));
  String _fmtDur(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _PdfViewer extends StatefulWidget {
  final FileItem file;
  const _PdfViewer({required this.file});
  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  String? _localPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.file.url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_preview.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) setState(() { _localPath = file.path; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.document));
    if (_localPath == null) return const Center(child: Text('Failed to load PDF', style: TextStyle(color: Colors.white)));
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: PDFView(filePath: _localPath),
    );
  }
}

class _TextViewer extends StatefulWidget {
  final FileItem file;
  const _TextViewer({required this.file});
  @override
  State<_TextViewer> createState() => _TextViewerState();
}

class _TextViewerState extends State<_TextViewer> {
  String? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse(widget.file.url)).then((r) {
      if (mounted) setState(() { _content = r.body; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _content ?? '',
          style: GoogleFonts.firaCode(color: Colors.white70, fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}

class _UnsupportedViewer extends StatelessWidget {
  final FileItem file;
  const _UnsupportedViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, color: Colors.white24, size: 80),
          const SizedBox(height: 24),
          Text(
            'No Preview Available',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'The file type ".${_ext(file.name)}" is not supported for in-app preview.',
            style: GoogleFonts.inter(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse(file.url)),
            icon: const Icon(Icons.open_in_browser_rounded),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Components ────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  const _Tag({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: textColor ?? Colors.white70),
      ),
    );
  }
}

class _FileActionsMenu extends StatelessWidget {
  final FileItem file;
  final bool isSmall;
  const _FileActionsMenu({required this.file, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) => _handle(context, val),
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: isSmall ? 18 : 22),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      itemBuilder: (context) => [
        _buildItem('preview', 'Preview', Icons.visibility_outlined),
        _buildItem('download', 'Download', Icons.file_download_outlined),
        _buildItem('share', 'Copy Link', Icons.link_rounded),
        const PopupMenuDivider(height: 1),
        _buildItem('delete', 'Delete', Icons.delete_outline_rounded, color: Colors.redAccent),
      ],
    );
  }

  PopupMenuItem<String> _buildItem(String val, String label, IconData icon, {Color? color}) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white70),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color ?? Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _handle(BuildContext context, String action) {
    switch (action) {
      case 'preview': _MediaViewer.show(context, file, [file]); break;
      case 'download': _download(context, file); break;
      case 'share':
        Clipboard.setData(ClipboardData(text: file.url));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
        break;
      case 'delete': _confirmDelete(context, file); break;
    }
  }
}

// ─── Actions Logic ────────────────────────────────────────────────────────────

Future<void> _download(BuildContext context, FileItem file) async {
  try {
    if (kIsWeb) {
      await launchUrl(Uri.parse(file.url), mode: LaunchMode.externalApplication);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading ${file.name}...')));

    final bytes = await Provider.of<FileProvider>(context, listen: false).downloadFile(file.blobName);
    
    String? path;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      path = await FilePicker.platform.saveFile(fileName: file.name);
    } else {
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      path = '${dir.path}/${file.name}';
    }

    if (path != null) {
      await File(path).writeAsBytes(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $path'),
            action: SnackBarAction(label: 'Open', onPressed: () => OpenFile.open(path)),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}

Future<void> _confirmDelete(BuildContext context, FileItem file) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
      content: Text('Are you sure you want to delete "${file.name}"?', style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    Provider.of<FileProvider>(context, listen: false).deleteFile(file.blobName, file.category);
  }
}

// ─── State Widgets ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text('Syncing with Azure...', style: GoogleFonts.inter(color: Colors.white54)),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text('Connection Error', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(error, style: GoogleFonts.inter(color: Colors.white54), textAlign: TextAlign.center),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasSearch ? Icons.search_off_rounded : Icons.folder_open_rounded, size: 80, color: Colors.white10),
          const SizedBox(height: 24),
          Text(
            hasSearch ? 'No matches found' : 'No files in $category',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white38),
          ),
          const SizedBox(height: 12),
          if (!hasSearch)
            ElevatedButton.icon(
              onPressed: () {}, // Trigger upload
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload First File'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}

// ─── Custom Colors for Categories ───────────────────────────────────────────

extension AppColorsExt on AppColors {
  static const music = Color(0xFFFACC15);
  static const document = Color(0xFF4ADE80);
}
