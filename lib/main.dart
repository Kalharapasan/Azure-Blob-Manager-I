import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/file_provider.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FileProvider(),
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        home: const DashboardScreen(),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const Color primary = Color(0xFF6C63FF);
    const Color surface = Color(0xFF0F0F1A);
    const Color surfaceVariant = Color(0xFF1A1A2E);
    const Color onSurface = Color(0xFFE8E8F0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF00D9FF),
        tertiary: Color(0xFFFF6B9D),
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        onSurface: onSurface,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF16162A),
        onPrimaryContainer: Color(0xFFB8B4FF),
        error: Color(0xFFFF5F7E),
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A45), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
