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
    return const Placeholder();
  }
}