import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/file_list.dart';
import '../widgets/file_upload_dialog.dart';
import '../widgets/storage_chart.dart';
import '../config/app_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String _selectedCategory = 'all';
  bool _isGridView = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
    );
    _fabAnimController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<FileProvider>(context, listen: false);
      p.loadStorageStats();
      p.loadFiles(_selectedCategory);
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _searchController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    if (category == 'private') {
      _showPasswordDialog();
    } else {
      setState(() {
        _selectedCategory = category;
        _searchQuery = '';
        _searchController.clear();
      });
      Provider.of<FileProvider>(context, listen: false).loadFiles(category);
    }
  }

  void _showPasswordDialog() {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (ctx) => _PrivatePasswordDialog(
        controller: _passwordController,
        onUnlock: () {
          setState(() => _selectedCategory = 'private');
          Provider.of<FileProvider>(context, listen: false).loadFiles('private');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withOpacity(0.05),
              ),
            ),
          ),
          Row(
            children: [
          // Sidebar
          CategorySidebar(
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategorySelected,
          ),
          // Main
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  searchController: _searchController,
                  isGridView: _isGridView,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  onToggleView: () => setState(() => _isGridView = !_isGridView),
                  onRefresh: () {
                    final p = Provider.of<FileProvider>(context, listen: false);
                    p.loadStorageStats();
                    p.loadFiles(_selectedCategory);
                  },
                ),
                // Storage chart (collapsible on narrow)
                if (isWide)
                  const SizedBox(
                    height: 220,
                    child: StorageChart(),
                  )
                else
                  const SizedBox(
                    height: 160,
                    child: StorageChart(),
                  ),
                const _SectionDivider(label: 'Files'),
                Expanded(
                  child: FileList(
                    category: _selectedCategory,
                    searchQuery: _searchQuery,
                    isGridView: _isGridView,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: _UploadFab(onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const FileUploadDialog(),
          );
        }),
      ),
    );
  }
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isGridView;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleView;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.searchController,
    required this.isGridView,
    required this.onSearchChanged,
    required this.onToggleView,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF07070F),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E35))),
      ),
      child: Row(
        children: [
          // Title + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Azure Blob Storage',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Search bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A45)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: TextStyle(color: cs.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search files…',
                  hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: cs.onSurface.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // View toggle
          _IconBtn(
            icon: isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            tooltip: isGridView ? 'List view' : 'Grid view',
            onTap: onToggleView,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A45)),
          ),
          child: Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }
}

// ─── Section Divider ─────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.35),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: const Color(0xFF2A2A45), height: 1)),
        ],
      ),
    );
  }
}

// ─── Upload FAB ──────────────────────────────────────────────────────────────

class _UploadFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _UploadFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Upload',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private Password Dialog ─────────────────────────────────────────────────

class _PrivatePasswordDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onUnlock;

  const _PrivatePasswordDialog({required this.controller, required this.onUnlock});

  @override
  State<_PrivatePasswordDialog> createState() => _PrivatePasswordDialogState();
}

class _PrivatePasswordDialogState extends State<_PrivatePasswordDialog> {
  bool _obscure = true;
  bool _shake = false;

  void _tryUnlock() {
    if (widget.controller.text == AppConfig.privateSectionPassword) {
      Navigator.of(context).pop();
      widget.onUnlock();
    } else {
      setState(() => _shake = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shake = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A2A45)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary.withOpacity(0.3), cs.tertiary.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.lock_rounded, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              'Private Section',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your password to access protected files',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(_shake ? 6 : 0, 0, 0),
              child: TextField(
                controller: widget.controller,
                obscureText: _obscure,
                autofocus: true,
                onSubmitted: (_) => _tryUnlock(),
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35)),
                  filled: true,
                  fillColor: const Color(0xFF0F0F1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A45)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A45)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: cs.onSurface.withOpacity(0.4),
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF2A2A45)),
                      ),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _tryUnlock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Unlock',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
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
