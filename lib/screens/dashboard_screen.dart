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

class _DashboardScreenState extends State<DashboardScreen> {

  String _selectedCategory = 'image';
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileProvider>(context, listen: false).loadStorageStats();
      Provider.of<FileProvider>(context, listen: false).loadFiles(_selectedCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        actions: [
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
              if (category == 'private') {
                _togglePrivateSection();
              } else {
                setState(() {
                  _selectedCategory = category;
                });
                Provider.of<FileProvider>(context, listen: false).loadFiles(category);
              }
            },
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Storage Dashboard (bounded height to avoid overflow)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.34,
                  child: StorageChart(),
                ),
                // File List
                Expanded(
                  flex: 3,
                  child: FileList(category: _selectedCategory),
                ),
              ],
            ),
          ),
          // Private section is now shown via the sidebar as a category.
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

  void _togglePrivateSection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter password to access private section',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _passwordController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_passwordController.text == AppConfig.privateSectionPassword) {
                setState(() {
                  _selectedCategory = 'private';
                });
                Provider.of<FileProvider>(context, listen: false).loadFiles('private');
                Navigator.of(context).pop();
                _passwordController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect password')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}