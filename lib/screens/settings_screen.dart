import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/model_download_service.dart';
import '../services/theme_service.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import 'model_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ThemeService _themeService = ThemeService();
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _modelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
    // Rebuild when theme changes (e.g. toggled from another screen)
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkModelStatus() async {
    final downloaded = await ModelDownloadService().isModelDownloaded();
    if (mounted) setState(() => _modelDownloaded = downloaded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const SizedBox(height: 16),

              // ── Account ──────────────────────────────────────────────────
              _buildSectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('EatCode — Free Tier'),
                subtitle: const Text('All features included · No sign-in required'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),

              // ── Preferences ───────────────────────────────────────────────
              _buildSectionHeader('Preferences'),
              SwitchListTile(
                secondary: Icon(
                  _themeService.isDark ? Icons.dark_mode : Icons.dark_mode_outlined,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(_themeService.isDark ? 'Dark theme active' : 'Switch to dark theme'),
                value: _themeService.isDark,
                onChanged: (v) => _themeService.setDark(v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Daily study reminders'),
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
              const Divider(),

              // ── AI Model ──────────────────────────────────────────────────
              _buildSectionHeader('AI Model'),
              ListTile(
                leading: Icon(
                  Icons.psychology,
                  color: _modelDownloaded ? const Color(0xFF4CAF50) : AppColors.textSecondary,
                ),
                title: const Text('On-Device AI'),
                subtitle: Text(
                  _modelDownloaded
                      ? 'Downloaded — AI generation active'
                      : 'Not downloaded — using curated templates',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModelSetupScreen(onSetupComplete: _checkModelStatus),
                    ),
                  );
                  _checkModelStatus();
                },
              ),
              const Divider(),

              // ── Data Management ───────────────────────────────────────────
              _buildSectionHeader('Data Management'),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset Progress'),
                subtitle: const Text('Clear all solved cards and confidence scores'),
                onTap: _handleResetProgress,
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Clear Bookmarks'),
                subtitle: const Text('Remove all saved bookmarks'),
                onTap: _handleClearBookmarks,
              ),
              const Divider(),

              // ── About ─────────────────────────────────────────────────────
              _buildSectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About EatCode'),
                onTap: _showAboutDialog,
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: _showPrivacyPolicy,
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: _showHelpSupport,
              ),

              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'EatCode v1.2.0',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Built with Flutter · On-device AI · 100% Offline',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
      ),
    );
  }

  Future<void> _handleResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
            'Clear all solved cards and confidence scores? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await _dbHelper.resetProgress();
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress has been reset')),
        );
      }
    }
  }

  Future<void> _handleClearBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Bookmarks'),
        content: const Text('Remove all bookmarks? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await _dbHelper.clearBookmarks();
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All bookmarks cleared')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF1565C0), size: 28),
            const SizedBox(width: 10),
            const Text('EatCode'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Version: 1.2.0', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Text(
                'EatCode is an offline-first flashcard app that helps you master '
                'coding interview problems through spaced repetition and on-device AI.',
              ),
              SizedBox(height: 16),
              Text('Features:', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('• 60 curated problems across 12 categories'),
              Text('• 24 company-specific interview problems'),
              Text('• Dual solutions: optimized + brute force'),
              Text('• AI-powered problem generator (on-device)'),
              Text('• Floating AI chat assistant per card'),
              Text('• Interview simulation mode'),
              Text('• Progress tracking & bookmarks'),
              Text('• 100% offline — no account required'),
              SizedBox(height: 16),
              Text('Tech Stack:', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('• Flutter · Dart · SQLite · MediaPipe'),
              Text('• On-device LLM (~900 MB, fully offline)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'EatCode stores all data locally on your device.\n\n'
            '• No account or sign-in required\n'
            '• No internet connection needed (after optional AI model download)\n'
            '• No analytics, tracking, or telemetry collected\n'
            '• Your progress, bookmarks, and chat history never leave your device\n\n'
            'The optional CodeGemma 2B model is downloaded once from Google\'s '
            'servers and runs entirely on-device thereafter.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Quick Tips:', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('• Tap a card to flip between Question / Solution'),
            Text('• Both optimized and brute-force solutions are shown'),
            Text('• Tap the ✓ icon to mark a card as solved'),
            Text('• Tap 🔖 to bookmark cards for later review'),
            Text('• Use the floating AI button to ask questions about any card'),
            Text('• Timer tracks how long you spend on each problem'),
            SizedBox(height: 16),
            Text('AI Model:', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'The on-device AI model (~900 MB) enables AI problem generation '
              'and smarter chat answers. Without it the app uses curated templates '
              '— all features still work.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
