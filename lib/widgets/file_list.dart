import 'dart:io';
import 'dart:typed_data';
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
import 'package:http/http.dart' as http;
import '../providers/file_provider.dart';
import '../models/file_item.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _categoryColor(String category) {
  switch (category) {
    case 'image':    return const Color(0xFF4ECDC4);
    case 'video':    return const Color(0xFFFF6B9D);
    case 'music':    return const Color(0xFFFFD93D);
    case 'document': return const Color(0xFF6BCB77);
    default:         return const Color(0xFFFF9A3C);
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'image':    return Icons.image_rounded;
    case 'video':    return Icons.play_circle_rounded;
    case 'music':    return Icons.music_note_rounded;
    case 'document': return Icons.description_rounded;
    default:         return Icons.extension_rounded;
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
}

String _ext(String name) =>
    name.contains('.') ? name.split('.').last.toLowerCase() : '';

bool _isTextExt(String ext) => [
      'txt', 'md', 'json', 'xml', 'csv', 'yaml', 'yml',
      'html', 'htm', 'css', 'js', 'ts', 'dart', 'py',
      'java', 'kt', 'swift', 'c', 'cpp', 'h', 'sh',
      'log', 'ini', 'conf', 'toml', 'env',
    ].contains(ext);

bool _isImageExt(String ext) =>
    ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);

bool _isVideoExt(String ext) =>
    ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'].contains(ext);

bool _isAudioExt(String ext) =>
    ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'opus'].contains(ext);

// ─── FileList ────────────────────────────────────────────────────────────────

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
        itemBuilder: (ctx, i) => _FileGridCard(file: files[i], index: i),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: files.length,
      itemBuilder: (ctx, i) => _FileListCard(file: files[i], index: i),
    );
  }
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
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 40),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(widget.file.category);
    final f = widget.file;

    return FadeTransition(
      opacity: _fade,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? color.withOpacity(0.08) : const Color(0xFF131326),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered ? color.withOpacity(0.4) : const Color(0xFF2A2A45),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))]
                : [],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openViewer(context, f),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                _FileThumbnail(file: f, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
                    const SizedBox(height: 3),
                    Row(children: [
                      _Chip(label: f.category, color: color),
                      const SizedBox(width: 6),
                      _Chip(label: _formatSize(f.size), color: Colors.white30),
                      if (f.isPrivate) ...[
                        const SizedBox(width: 6),
                        _Chip(label: 'Private', color: const Color(0xFFB8B4FF), icon: Icons.lock_rounded),
                      ],
                    ]),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(_fmtDate(f.uploadedAt),
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.35))),
                const SizedBox(width: 8),
                _FileActions(file: f),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
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
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(widget.file.category);
    final f = widget.file;

    return FadeTransition(
      opacity: _fade,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered ? color.withOpacity(0.08) : const Color(0xFF131326),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? color.withOpacity(0.5) : const Color(0xFF2A2A45),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))]
                : [],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openViewer(context, f),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _FileThumbnail(file: f, size: 48),
                  const Spacer(),
                  _FileActions(file: f),
                ]),
                const Spacer(),
                Text(f.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface, height: 1.3)),
                const SizedBox(height: 6),
                Row(children: [
                  _Chip(label: _formatSize(f.size), color: Colors.white30),
                  if (f.isPrivate) ...[
                    const SizedBox(width: 6),
                    _Chip(label: 'Private', color: const Color(0xFFB8B4FF), icon: Icons.lock_rounded),
                  ],
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

class _FileThumbnail extends StatelessWidget {
  final FileItem file;
  final double size;
  const _FileThumbnail({required this.file, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(file.category);
    final ext = _ext(file.name);

    if (_isImageExt(ext)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.27),
        child: Image.network(
          file.url,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconBox(color),
        ),
      );
    }

    if (_isVideoExt(ext)) {
      return Stack(children: [
        _iconBox(color),
        Positioned.fill(child: Icon(Icons.play_circle_fill_rounded, color: color.withOpacity(0.6), size: size * 0.45)),
      ]);
    }

    return _iconBox(color);
  }

  Widget _iconBox(Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(size * 0.27),
    ),
    child: Icon(_categoryIcon(file.category), color: color, size: size * 0.5),
  );
}

// ─── Viewer dispatcher ────────────────────────────────────────────────────────

void _openViewer(BuildContext context, FileItem file) {
  final ext = _ext(file.name);
  Widget dialog;

  if (_isImageExt(ext)) {
    dialog = _ImageViewer(file: file);
  } else if (_isVideoExt(ext)) {
    dialog = _VideoViewer(file: file);
  } else if (_isAudioExt(ext)) {
    dialog = _AudioViewer(file: file);
  } else if (_isTextExt(ext)) {
    dialog = _TextViewer(file: file);
  } else {
    dialog = _FileInfoDialog(file: file);
  }

  showDialog(context: context, builder: (_) => dialog);
}

// ─── Image Viewer ─────────────────────────────────────────────────────────────

class _ImageViewer extends StatelessWidget {
  final FileItem file;
  const _ImageViewer({required this.file});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A45)),
          ),
          child: Column(children: [
            _ViewerHeader(file: file),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: PhotoView(
                  imageProvider: NetworkImage(file.url),
                  backgroundDecoration: const BoxDecoration(color: Color(0xFF0A0A14)),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  loadingBuilder: (_, __) =>
                      const Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4))),
                  errorBuilder: (_, __, ___) => Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.broken_image_rounded, color: Color(0xFF4ECDC4), size: 56),
                      const SizedBox(height: 12),
                      Text('Cannot load image',
                          style: TextStyle(color: Colors.white.withOpacity(0.4))),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Video Viewer ─────────────────────────────────────────────────────────────

class _VideoViewer extends StatefulWidget {
  final FileItem file;
  const _VideoViewer({required this.file});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.file.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
        _ctrl.play();
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A45)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _ViewerHeader(file: widget.file),
            Flexible(
              child: GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: Container(
                  color: Colors.black,
                  child: _hasError
                      ? _errorView()
                      : !_initialized
                          ? const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D))))
                          : Stack(alignment: Alignment.center, children: [
                              AspectRatio(
                                aspectRatio: _ctrl.value.aspectRatio,
                                child: VideoPlayer(_ctrl),
                              ),
                              if (_showControls) _controls(),
                            ]),
                ),
              ),
            ),
            if (_initialized && !_hasError) _scrubber(),
          ]),
        ),
      ),
    );
  }

  Widget _controls() {
    final playing = _ctrl.value.isPlaying;
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0x88000000), Colors.transparent],
            radius: 0.7,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ctrlBtn(Icons.replay_10_rounded, () {
            _ctrl.seekTo(_ctrl.value.position - const Duration(seconds: 10));
          }),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => playing ? _ctrl.pause() : _ctrl.play(),
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B9D).withOpacity(0.9),
              ),
              child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          _ctrlBtn(Icons.forward_10_rounded, () {
            _ctrl.seekTo(_ctrl.value.position + const Duration(seconds: 10));
          }),
        ]),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 44, height: 44,
      decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white70, size: 24),
    ),
  );

  Widget _scrubber() {
    final pos = _ctrl.value.position;
    final dur = _ctrl.value.duration;
    final prog = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      color: const Color(0xFF0A0A14),
      child: Column(children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFFFF6B9D),
            inactiveTrackColor: const Color(0xFF2A2A45),
            thumbColor: const Color(0xFFFF6B9D),
            overlayColor: const Color(0xFFFF6B9D).withOpacity(0.2),
          ),
          child: Slider(
            value: prog.clamp(0.0, 1.0),
            onChanged: (v) =>
                _ctrl.seekTo(Duration(milliseconds: (v * dur.inMilliseconds).round())),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmt(pos), style: const TextStyle(color: Colors.white38, fontSize: 11)),
          IconButton(
            onPressed: () {
              _ctrl.setVolume(_ctrl.value.volume == 0 ? 1.0 : 0.0);
              setState(() {});
            },
            icon: Icon(
              _ctrl.value.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white38, size: 18,
            ),
          ),
          Text(_fmt(dur), style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _errorView() => SizedBox(
    height: 200,
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.videocam_off_rounded, color: Color(0xFFFF6B9D), size: 56),
        const SizedBox(height: 12),
        const Text('Cannot play video', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () =>
              launchUrl(Uri.parse(widget.file.url), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Open externally'),
        ),
      ]),
    ),
  );
}

// ─── Audio Viewer ─────────────────────────────────────────────────────────────

class _AudioViewer extends StatefulWidget {
  final FileItem file;
  const _AudioViewer({required this.file});

  @override
  State<_AudioViewer> createState() => _AudioViewerState();
}

class _AudioViewerState extends State<_AudioViewer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = true;
  bool _hasError = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _player.setUrl(widget.file.url).then((_) {
      if (mounted) setState(() => _loading = false);
    }).catchError((_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    });

    _player.playerStateStream.listen((_) { if (mounted) setState(() {}); });
    _player.positionStream.listen((_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _player.dispose(); _pulse.dispose(); super.dispose(); }

  String _fmt(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playing = _player.playerState.playing;
    final pos = _player.position;
    final dur = _player.duration ?? Duration.zero;
    final prog = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A2A45)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _ViewerHeader(file: widget.file),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: _hasError
                ? _errorView()
                : Column(children: [
                    // Waveform visualization
                    SizedBox(
                      height: 80,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => CustomPaint(
                          painter: _WaveformPainter(
                            progress: playing ? _pulse.value : 0.0,
                            color: const Color(0xFFFFD93D),
                          ),
                          size: const Size(double.infinity, 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_loading)
                      const CircularProgressIndicator(color: Color(0xFFFFD93D))
                    else
                      GestureDetector(
                        onTap: () => playing ? _player.pause() : _player.play(),
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD93D), Color(0xFFFF9A3C)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD93D).withOpacity(0.4),
                                blurRadius: 20, spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black, size: 38,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: const Color(0xFFFFD93D),
                        inactiveTrackColor: const Color(0xFF2A2A45),
                        thumbColor: const Color(0xFFFFD93D),
                        overlayColor: const Color(0xFFFFD93D).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: prog.clamp(0.0, 1.0),
                        onChanged: (v) => _player.seek(
                            Duration(milliseconds: (v * dur.inMilliseconds).round())),
                      ),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_fmt(pos), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      Text(_fmt(dur), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ]),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _speedBtn('0.5x', 0.5),
                      const SizedBox(width: 8),
                      _speedBtn('1x', 1.0),
                      const SizedBox(width: 8),
                      _speedBtn('1.5x', 1.5),
                      const SizedBox(width: 8),
                      _speedBtn('2x', 2.0),
                    ]),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _speedBtn(String label, double speed) {
    final active = (_player.speed - speed).abs() < 0.01;
    return GestureDetector(
      onTap: () { _player.setSpeed(speed); setState(() {}); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD93D).withOpacity(0.2) : const Color(0xFF2A2A45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? const Color(0xFFFFD93D) : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11,
          color: active ? const Color(0xFFFFD93D) : Colors.white38,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        )),
      ),
    );
  }

  Widget _errorView() => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.music_off_rounded, color: Color(0xFFFFD93D), size: 56),
    const SizedBox(height: 12),
    const Text('Cannot play audio', style: TextStyle(color: Colors.white54)),
    const SizedBox(height: 8),
    TextButton.icon(
      onPressed: () =>
          launchUrl(Uri.parse(widget.file.url), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.open_in_new_rounded, size: 16),
      label: const Text('Open externally'),
    ),
  ]);
}

// ─── Waveform Painter ─────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  _WaveformPainter({required this.progress, required this.color});

  static const _heights = [
    0.3, 0.5, 0.8, 0.4, 0.7, 0.9, 0.5, 0.6, 0.8, 0.3,
    0.7, 0.4, 0.9, 0.6, 0.5, 0.8, 0.3, 0.7, 0.5, 0.9,
    0.4, 0.6, 0.8, 0.3, 0.7, 0.5, 0.9, 0.6, 0.4, 0.8,
    0.3, 0.7, 0.5, 0.9, 0.4, 0.6, 0.8, 0.3, 0.5, 0.7,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bars = _heights.length;
    final bw = size.width / (bars * 2);
    for (int i = 0; i < bars; i++) {
      final pulse = 1.0 + progress * 0.45 * ((i % 3 == 0) ? 1.0 : 0.5);
      final h = size.height * _heights[i] * pulse;
      final x = (i * 2 + 1) * bw;
      final top = (size.height - h) / 2;
      canvas.drawLine(
        Offset(x, top), Offset(x, top + h),
        Paint()
          ..color = color.withOpacity(0.65)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress;
}

// ─── Text Viewer ──────────────────────────────────────────────────────────────

class _TextViewer extends StatefulWidget {
  final FileItem file;
  const _TextViewer({required this.file});

  @override
  State<_TextViewer> createState() => _TextViewerState();
}

class _TextViewerState extends State<_TextViewer> {
  String? _content;
  bool _loading = true;
  bool _hasError = false;
  double _fontSize = 13;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse(widget.file.url));
      if (r.statusCode == 200) {
        setState(() { _content = r.body; _loading = false; });
      } else {
        setState(() { _hasError = true; _loading = false; });
      }
    } catch (_) {
      setState(() { _hasError = true; _loading = false; });
    }
  }

  Color _textColor(String ext) {
    if (['json', 'yaml', 'yml', 'toml'].contains(ext)) return const Color(0xFF6BCB77);
    if (['html', 'htm', 'xml'].contains(ext)) return const Color(0xFFFF9A3C);
    if (['js', 'ts', 'dart', 'py', 'java', 'kt', 'swift', 'c', 'cpp'].contains(ext))
      return const Color(0xFF9B95FF);
    if (['css'].contains(ext)) return const Color(0xFF4ECDC4);
    if (['sh', 'bash', 'conf', 'ini'].contains(ext)) return const Color(0xFFFF9A3C);
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = _ext(widget.file.name);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A45)),
          ),
          child: Column(children: [
            _ViewerHeader(
              file: widget.file,
              trailing: Row(children: [
                _iconBtn(Icons.remove_rounded, () => setState(() => _fontSize = (_fontSize - 1).clamp(8, 24))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('${_fontSize.toInt()}pt',
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ),
                _iconBtn(Icons.add_rounded, () => setState(() => _fontSize = (_fontSize + 1).clamp(8, 24))),
                const SizedBox(width: 6),
                _iconBtn(Icons.copy_rounded, () {
                  if (_content != null) {
                    Clipboard.setData(ClipboardData(text: _content!));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')));
                  }
                }),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6BCB77)))
                  : _hasError
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.error_outline_rounded, color: cs.error, size: 48),
                            const SizedBox(height: 12),
                            const Text('Could not load file',
                                style: TextStyle(color: Colors.white38)),
                          ]),
                        )
                      : Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: SelectableText(
                              _content ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: _fontSize,
                                color: _textColor(ext),
                                height: 1.65,
                              ),
                            ),
                          ),
                        ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: Colors.white54),
    ),
  );
}

// ─── File Info (unsupported types) ────────────────────────────────────────────

class _FileInfoDialog extends StatelessWidget {
  final FileItem file;
  const _FileInfoDialog({required this.file});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(file.category);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A45)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _ViewerHeader(file: file),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A45)),
                ),
                child: Column(children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(_categoryIcon(file.category), color: color, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No built-in preview for .${_ext(file.name)} files',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        launchUrl(Uri.parse(file.url), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Open in Browser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              _MetaRow('Name', file.name),
              _MetaRow('Category', file.category),
              _MetaRow('Size', _formatSize(file.size)),
              _MetaRow('Uploaded', file.uploadedAt.toLocal().toString().split('.').first),
              _MetaRow('Private', file.isPrivate ? 'Yes' : 'No'),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared Viewer Header ─────────────────────────────────────────────────────

class _ViewerHeader extends StatelessWidget {
  final FileItem file;
  final Widget? trailing;
  const _ViewerHeader({required this.file, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(file.category);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_categoryIcon(file.category), color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
            Text(_formatSize(file.size),
                style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4))),
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded, color: cs.onSurface.withOpacity(0.5), size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
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
        if (value == 'delete')   _delete(context);
        if (value == 'download') _download(context);
        if (value == 'preview')  _openViewer(context, file);
        if (value == 'share')    _copyLink(context);
      },
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2A2A45)),
      ),
      itemBuilder: (_) => [
        _item('preview',  'Open & View', Icons.visibility_rounded),
        _item('download', 'Download',    Icons.download_rounded),
        _item('share',    'Copy Link',   Icons.link_rounded),
        const PopupMenuDivider(),
        _item('delete',   'Delete',      Icons.delete_outline_rounded, destructive: true),
      ],
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white54),
      ),
    );
  }

  PopupMenuItem<String> _item(String value, String label, IconData icon, {bool destructive = false}) {
    final color = destructive ? const Color(0xFFFF5F7E) : Colors.white70;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ]),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: file.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDeleteDialog(fileName: file.name),
    );
    if (confirmed == true && context.mounted) {
      Provider.of<FileProvider>(context, listen: false)
          .deleteFile(file.blobName, file.category);
    }
  }

  Future<void> _download(BuildContext context) async {
    try {
      if (kIsWeb) {
        try {
          await launchUrl(Uri.parse(file.url), mode: LaunchMode.externalApplication);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening in new tab...')),
            );
          }
        } catch (_) {
          if (context.mounted) {
            showDialog(context: context, builder: (_) => _ManualDownloadDialog(url: file.url));
          }
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Text('Downloading ${file.name}…'),
          ]),
          duration: const Duration(seconds: 60),
        ));
      }

      final bytes = await Provider.of<FileProvider>(context, listen: false)
          .downloadFile(file.blobName);

      String? outputPath;
      final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      if (isDesktop) {
        try {
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save ${file.name}', fileName: file.name,
          );
        } catch (_) {}
      }

      if (outputPath == null && !kIsWeb) {
        try {
          Directory? dir;
          if (Platform.isAndroid) {
            final ext = Directory('/storage/emulated/0/Download');
            dir = await ext.exists() ? ext : await getApplicationDocumentsDirectory();
          } else {
            dir = await getApplicationDocumentsDirectory();
          }
          outputPath = '${dir.path}/${file.name}';
        } catch (_) {
          final fb = await getApplicationDocumentsDirectory();
          outputPath = '${fb.path}/${file.name}';
        }
      }

      if (outputPath != null) {
        await File(outputPath).writeAsBytes(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Saved: ${outputPath.split(RegExp(r'[/\\]')).last}'),
            backgroundColor: const Color(0xFF4ECDC4),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(outputPath!),
            ),
          ));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Download cancelled'),
            backgroundColor: Color(0xFFFF9A3C),
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: const Color(0xFFFF5F7E),
        ));
      }
    }
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 9, color: color), const SizedBox(width: 3)],
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}

// ─── Meta Row ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final String label, value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
        ),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.75),
                  fontWeight: FontWeight.w500)),
        ),
      ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: cs.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 26),
          ),
          const SizedBox(height: 16),
          Text('Delete File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to delete "$fileName"? This cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.55)),
          ),
          const SizedBox(height: 24),
          Row(children: [
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Manual Download Dialog ───────────────────────────────────────────────────

class _ManualDownloadDialog extends StatelessWidget {
  final String url;
  const _ManualDownloadDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A45)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Icon(Icons.link_off_rounded, color: cs.error, size: 24),
            const SizedBox(width: 12),
            Text('Download Link',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          ]),
          const SizedBox(height: 16),
          Text('Download was blocked. Use the link below:',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.6), height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A45)),
            ),
            child: SelectableText(url,
                style: TextStyle(fontSize: 11, color: cs.primary, height: 1.4), maxLines: 4),
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: cs.onSurface.withOpacity(0.5))),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
                catch (_) {}
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A45),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')));
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 40, height: 40,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
        const SizedBox(height: 16),
        Text('Loading files…',
            style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 13)),
      ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_rounded, color: cs.error, size: 48),
        const SizedBox(height: 12),
        Text('Failed to load files',
            style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(error,
            style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 12),
            textAlign: TextAlign.center),
      ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(hasSearch ? Icons.search_off_rounded : Icons.folder_open_rounded,
            size: 56, color: cs.onSurface.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text(
          hasSearch ? 'No files match your search' : 'No files in this category',
          style: TextStyle(
              color: cs.onSurface.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Text(
          hasSearch ? 'Try a different search term' : 'Upload files using the button below',
          style: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 12),
        ),
      ]),
    );
  }
}
