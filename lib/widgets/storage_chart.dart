import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';

class StorageChart extends StatefulWidget {
  const StorageChart({super.key});

  @override
  State<StorageChart> createState() => _StorageChartState();
}

class _StorageChartState extends State<StorageChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (fileProvider.isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final files = fileProvider.files;
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline_rounded,
                size: 28, color: cs.onSurface.withOpacity(0.2)),
            const SizedBox(height: 6),
            Text('No data',
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.35), fontSize: 11)),
          ],
        ),
      );
    }

    final Map<String, int> categorySizes = {};
    int totalSize = 0;
    int totalFiles = 0;

    for (final f in files) {
      final cat = f.category;
      final sz = f.size;
      categorySizes[cat] = (categorySizes[cat] ?? 0) + sz;
      totalSize += sz;
      totalFiles++;
    }

    final categoryColors = {
      'image': const Color(0xFF4ECDC4),
      'video': const Color(0xFFFF6B9D),
      'music': const Color(0xFFFFD93D),
      'document': const Color(0xFF6BCB77),
      'other': const Color(0xFFFF9A3C),
    };

    final sections = <PieChartSectionData>[];
    final entries = categorySizes.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final cat = entries[i].key;
      final sz = entries[i].value;
      final pct = totalSize > 0 ? (sz / totalSize) * 100 : 0.0;
      final isTouched = i == _touchedIndex;
      final color = categoryColors[cat] ?? const Color(0xFF6C63FF);

      sections.add(PieChartSectionData(
        value: sz.toDouble(),
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        radius: isMobile
            ? (isTouched ? 38 : 32)
            : (isTouched ? 52 : 44),
        color: color,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        borderSide: isTouched
            ? BorderSide(color: color.withOpacity(0.6), width: 3)
            : const BorderSide(color: Colors.transparent),
      ));
    }

    if (isMobile) {
      return _buildMobileChart(context, cs, entries, sections, categoryColors, totalSize, totalFiles);
    } else {
      return _buildWideChart(context, cs, entries, sections, categoryColors, totalSize, totalFiles);
    }
  }

  // ── Mobile: horizontal compact layout ────────────────────────────────────
  Widget _buildMobileChart(
    BuildContext context,
    ColorScheme cs,
    List<MapEntry<String, int>> entries,
    List<PieChartSectionData> sections,
    Map<String, Color> categoryColors,
    int totalSize,
    int totalFiles,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131326).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A45), width: 1.5),
      ),
      child: Row(
        children: [
          // Compact pie chart
          SizedBox(
            width: 100,
            height: 100,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 24,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = null;
                        return;
                      }
                      final index = response.touchedSection!.touchedSectionIndex;
                      _touchedIndex = index >= 0 ? index : null;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Storage Usage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatSize(totalSize)} · $totalFiles files',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 8),
                // Legend compact
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entries.map((e) {
                    final color = categoryColors[e.key] ?? const Color(0xFF6C63FF);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _capitalize(e.key),
                          style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Summary column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStatCard(
                icon: Icons.insert_drive_file_rounded,
                value: '$totalFiles',
                label: 'Files',
                color: cs.primary,
              ),
              const SizedBox(height: 8),
              _MiniStatCard(
                icon: Icons.data_usage_rounded,
                value: _formatSize(totalSize),
                label: 'Size',
                color: cs.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Wide: original layout ─────────────────────────────────────────────────
  Widget _buildWideChart(
    BuildContext context,
    ColorScheme cs,
    List<MapEntry<String, int>> entries,
    List<PieChartSectionData> sections,
    Map<String, Color> categoryColors,
    int totalSize,
    int totalFiles,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131326).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2A45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140, height: 140,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 32,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = null;
                        return;
                      }
                      final index = response.touchedSection!.touchedSectionIndex;
                      _touchedIndex = index >= 0 ? index : null;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage Usage',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatSize(totalSize)} total · $totalFiles files',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: entries.map((e) {
                    final color = categoryColors[e.key] ?? const Color(0xFF6C63FF);
                    final pct = totalSize > 0 ? (e.value / totalSize * 100) : 0.0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_capitalize(e.key)} ${pct.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.55)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatCard(
                icon: Icons.insert_drive_file_rounded,
                label: 'Total Files',
                value: '$totalFiles',
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.data_usage_rounded,
                label: 'Total Size',
                value: _formatSize(totalSize),
                color: cs.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Mini stat card for mobile ─────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card for wide ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(0.4),
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
