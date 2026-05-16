import 'package:flutter/material.dart';

class CategorySidebar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySidebar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<_CategoryItem> _items = [
    _CategoryItem('all', 'All Files', Icons.folder_rounded, Color(0xFF6C63FF)),
    _CategoryItem('image', 'Images', Icons.image_rounded, Color(0xFF4ECDC4)),
    _CategoryItem('video', 'Videos', Icons.play_circle_rounded, Color(0xFFFF6B9D)),
    _CategoryItem('music', 'Music', Icons.music_note_rounded, Color(0xFFFFD93D)),
    _CategoryItem('document', 'Documents', Icons.description_rounded, Color(0xFF6BCB77)),
    _CategoryItem('other', 'Other', Icons.extension_rounded, Color(0xFFFF9A3C)),
    _CategoryItem('private', 'Private', Icons.lock_rounded, Color(0xFFB8B4FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(right: BorderSide(color: Color(0xFF1E1E35))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BlobVault',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE8E8F0),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'File Manager',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF5A5A80),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.25),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final bool selected = selectedCategory == item.key;
                return _SidebarTile(
                  item: item,
                  selected: selected,
                  onTap: () => onCategorySelected(item.key),
                );
              },
            ),
          ),
          // Bottom user area
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Azure Storage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8E8F0),
                        ),
                      ),
                      Text(
                        'Connected',
                        style: TextStyle(fontSize: 10, color: Color(0xFF4ECDC4)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ECDC4),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String key;
  final String label;
  final IconData icon;
  final Color accent;
  const _CategoryItem(this.key, this.label, this.icon, this.accent);
}

class _SidebarTile extends StatefulWidget {
  final _CategoryItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.selected, required this.onTap});

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final accent = widget.item.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withOpacity(0.15)
                : _hovered
                    ? Colors.white.withOpacity(0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent.withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 16,
                  color: selected ? accent : Colors.white.withOpacity(0.45),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? accent : Colors.white.withOpacity(0.55),
                ),
              ),
              if (selected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
