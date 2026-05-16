import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/file_list.dart';
import '../widgets/file_upload_dialog.dart';
import '../widgets/storage_chart.dart';
import '../widgets/private_section.dart';
import '../config/app_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  String _selectedCategory = 'image';
  bool _showPrivate = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: _togglePrivateSection,
            tooltip: _showPrivate ? 'Hide Private Section' : 'Show Private Section',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<FileProvider>(context, listen: false).loadStorageStats();
              Provider.of<FileProvider>(context, listen: false).loadFiles(_selectedCategory);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          CategorySidebar(
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
                Provider.of<FileProvider>(context, listen: false).loadFiles(category);
              });
            },
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Storage Dashboard
                Expanded(
                  flex: 2,
                  child: StorageChart(),
                ),
                // File List
                Expanded(
                  flex: 3,
                  child: FileList(
                    category: _selectedCategory,
                    showPrivate: _showPrivate,
                  ),
                ),
              ],
            ),
          ),
          if (_showPrivate)
            const PrivateSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        tooltip: 'Upload File',
        child: const Icon(Icons.upload),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => const FileUploadDialog(),
    );
  }

  void _togglePrivateSection() {}
}