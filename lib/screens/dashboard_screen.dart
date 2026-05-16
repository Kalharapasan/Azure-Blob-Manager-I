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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    // Close drawer on mobile after selection
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }

    if (category == 'private') {
      _showPasswordDialog();
    } else {
      setState(() {
        _selectedCategory = category;
        _searchQuery = '';
        _searchController.clear();
      });
      Provider.of<FileProvider>(context, listen: false).loadFiles('all');
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
          Provider.of<FileProvider>(context, listen: false).loadFiles('all');
        },
      ),
    );
  }

  String get _categoryLabel {
    switch (_selectedCategory) {
      case 'all': return 'All Files';
      case 'image': return 'Images';
      case 'video': return 'Videos';
      case 'music': return 'Music';
      case 'document': return 'Documents';
      case 'other': return 'Other';
      case 'private': return 'Private';
      default: return 'Files';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    if (isWide) {
      return _buildWideLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // ── Wide Layout (tablet/desktop) ──────────────────────────────────────────
  Widget _buildWideLayout() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withOpacity(0.05),
              ),
            ),
          ),
          Row(
            children: [
              CategorySidebar(
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),
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
                    const SizedBox(height: 220, child: StorageChart()),
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
          showDialog(context: context, builder: (_) => const FileUploadDialog());
        }),
      ),
    );
  }

  // ── Mobile Layout ─────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF07070F),
      // Drawer for category navigation
      drawer: Drawer(
        backgroundColor: const Color(0xFF0D0D1A),
        child: CategorySidebar(
          selectedCategory: _selectedCategory,
          onCategorySelected: _onCategorySelected,
        ),
      ),
      // App Bar
      appBar: _MobileAppBar(
        categoryLabel: _categoryLabel,
        isGridView: _isGridView,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onToggleView: () => setState(() => _isGridView = !_isGridView),
        onRefresh: () {
          final p = Provider.of<FileProvider>(context, listen: false);
          p.loadStorageStats();
          p.loadFiles(_selectedCategory);
        },
      ),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            children: [
              // Search bar
              _MobileSearchBar(
                controller: _searchController,
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
              // Compact chart
              const SizedBox(height: 150, child: StorageChart()),
              const _SectionDivider(label: 'Files'),
              // File list
              Expanded(
                child: FileList(
                  category: _selectedCategory,
                  searchQuery: _searchQuery,
                  isGridView: _isGridView,
                ),
              ),
            ],
          ),
        ],
      ),
      // Upload FAB
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: _UploadFab(onPressed: () {
          showDialog(context: context, builder: (_) => const FileUploadDialog());
        }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Bottom nav for categories
      bottomNavigationBar: _MobileBottomNav(
        selectedCategory: _selectedCategory,
        onCategorySelected: _onCategorySelected,
      ),
    );
  }
}

// ─── Mobile AppBar ────────────────────────────────────────────────────────────

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryLabel;
  final bool isGridView;
  final VoidCallback onMenuTap;
  final VoidCallback onToggleView;
  final VoidCallback onRefresh;

  const _MobileAppBar({
    required this.categoryLabel,
    required this.isGridView,
    required this.onMenuTap,
    required this.onToggleView,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 64 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF07070F),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E35))),
      ),
      child: Row(
        children: [
          // Menu / hamburger
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded, color: Colors.white70, size: 24),
          ),
          // App icon + title
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'BlobVault',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE8E8F0),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  categoryLabel,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF5A5A80)),
                ),
              ],
            ),
          ),
          // View toggle
          IconButton(
            onPressed: onToggleView,
            icon: Icon(
              isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: Colors.white54,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Search Bar ────────────────────────────────────────────────────────

class _MobileSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _MobileSearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A45)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search files…',
            hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: cs.onSurface.withOpacity(0.4)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// ─── Mobile Bottom Navigation ─────────────────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _MobileBottomNav({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<_NavItem> _items = [
    _NavItem('all', 'All', Icons.folder_rounded, Color(0xFF6C63FF)),
    _NavItem('image', 'Images', Icons.image_rounded, Color(0xFF4ECDC4)),
    _NavItem('video', 'Videos', Icons.play_circle_rounded, Color(0xFFFF6B9D)),
    _NavItem('document', 'Docs', Icons.description_rounded, Color(0xFF6BCB77)),
    _NavItem('private', 'Private', Icons.lock_rounded, Color(0xFFB8B4FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Color(0xFF1E1E35), width: 1.5)),
      ),
      child: Row(
        children: _items.map((item) {
          final selected = selectedCategory == item.key;
          final color = item.color;
          return Expanded(
            child: GestureDetector(
              onTap: () => onCategorySelected(item.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: selected ? color : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? color : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _NavItem(this.key, this.label, this.icon, this.color);
}

// ─── Top Bar (wide only) ──────────────────────────────────────────────────────

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
          _IconBtn(
            icon: isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            tooltip: isGridView ? 'List view' : 'Grid view',
            onTap: onToggleView,
          ),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.refresh_rounded, tooltip: 'Refresh', onTap: onRefresh),
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
          width: 40, height: 40,
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

// ─── Section Divider ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const Expanded(child: Divider(color: Color(0xFF2A2A45), height: 1)),
        ],
      ),
    );
  }
}

// ─── Upload FAB ───────────────────────────────────────────────────────────────

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

// ─── Private Password Dialog ──────────────────────────────────────────────────

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
    // Use full screen dialog on mobile
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 80)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
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
              width: 56, height: 56,
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
                fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your password to access protected files',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5)),
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
                      gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _tryUnlock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Unlock',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
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
