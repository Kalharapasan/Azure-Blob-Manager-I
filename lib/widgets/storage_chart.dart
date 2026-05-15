import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';

class StorageChart extends StatelessWidget {
  const StorageChart({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = fileProvider.storageStats;
    final categorySizes = stats['categorySizes'] as Map<String, int>? ?? {};

    final fileProvider = Provider.of<FileProvider>(context);

    if (fileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fileProvider.error != null) {
      return Center(
        child: Text('Error: ${fileProvider.error}'),
      );
    }

    if (categorySizes.isEmpty) {
      return const Center(
        child: Text('No storage data available'),
      );
    }

    

    return const Placeholder();
  }
}