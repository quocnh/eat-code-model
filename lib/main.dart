import 'dart:async';
import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'database/database_helper.dart';
import 'services/navigation_service.dart';
import 'services/model_download_service.dart';
import 'services/path_progress_service.dart';
import 'screens/model_setup_screen.dart';

void main() {
  // ensureInitialized must be in the same zone as runApp to avoid zone-mismatch
  // warnings that can mask real errors. runZonedGuarded absorbs uncaught async
  // errors so a MediaPipe/Gemma channel error never crashes the whole app.
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    },
    (error, stack) {
      // Log but do not rethrow — the app continues in template-fallback mode.
      debugPrint('[EatCode] Caught zone error: $error');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EatCode',
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
      ),
      home: const _AppInitializer(),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

/// Initializes the database, checks model status, and routes to the correct screen.
///
/// Flow:
///   1. Init DB + seed problems (always uses TemplateLlmService — fast, offline)
///   2. Check if CodeGemma model is downloaded
///      • Not downloaded → show [ModelSetupScreen] (user can download or skip)
///      • Downloaded → initialize [GemmaLlmService] and go to home
class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  String _statusMessage = 'Starting up…';

  @override
  void initState() {
    super.initState();
    // Errors are absorbed by runZonedGuarded in main(); catch here too for safety.
    _initialize().catchError((e) => debugPrint('[EatCode] Init error: $e'));
  }

  Future<void> _initialize() async {
    final dbHelper = DatabaseHelper();

    // ── 1. Load persisted user progress ────────────────────────────────────
    await PathProgressService().init();

    // ── 2. Init DB ─────────────────────────────────────────────────────────
    await dbHelper.database;

    // ── 2. Seed problems (TemplateLlmService, always works) ────────────────
    setState(() => _statusMessage = 'Generating your problem library…');
    await dbHelper.insertSampleData();

    // ── 3. Check CodeGemma model ────────────────────────────────────────────
    final modelReady = await ModelDownloadService().isModelDownloaded();

    if (!mounted) return;

    if (!modelReady) {
      // First time or model was deleted — show setup screen.
      // User can download or tap "Skip" to use template mode.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ModelSetupScreen(
            onSetupComplete: _onModelReady,
          ),
        ),
      );
    } else {
      await _onModelReady();
    }
  }

  /// Called after model is confirmed present (or just downloaded).
  /// Navigates straight to home — GemmaLlmService initialises lazily on
  /// first use, so we never block the UI or risk an unhandled platform error.
  Future<void> _onModelReady() async {
    NavigationService.navigatorKey.currentState
        ?.pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.psychology,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'EatCode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by on-device AI',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
