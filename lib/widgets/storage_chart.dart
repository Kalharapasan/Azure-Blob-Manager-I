import 'package:flutter/material.dart';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';

class StorageChart extends StatelessWidget {
  const StorageChart({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = Provider.of<FileProvider>(context);

    if (fileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fileProvider.error != null) {
      return Center(child: Text('Error: ${fileProvider.error}'));
    }

    final stats = fileProvider.storageStats;
    final categorySizes = stats['categorySizes'] as Map<String, int>? ?? {};

    if (categorySizes.isEmpty) {
      return const Center(child: Text('No storage data available'));
    }

    // Prepare data for the pie chart
    final List<PieChartSectionData> sections = [];
    int totalSize = 0;
    categorySizes.forEach((category, size) {
      totalSize += size;
    });

    categorySizes.forEach((category, size) {
      final double percentage = (size / totalSize) * 100;
      sections.add(
        PieChartSectionData(
          value: size.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          color: _getColorForCategory(category),
        ),
      );
    });

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.25;
          final double chartHeight = min(availableHeight * 0.6, 300);

          return SizedBox(
            height: availableHeight,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Storage Usage by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: chartHeight,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Data Analytics & Summary',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: min(300, MediaQuery.of(context).size.width * 0.4)),
                            child: _buildSummaryCard(context, 'Total Files', '${stats['totalFiles'] ?? 0}', Icons.insert_drive_file),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: min(300, MediaQuery.of(context).size.width * 0.4)),
                            child: _buildSummaryCard(context, 'Total Size', '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB', Icons.data_usage),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'video':
        return Colors.red;
      case 'image':
        return Colors.blue;
      case 'music':
        return Colors.green;
      case 'document':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
