import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/model_download_service.dart';
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
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _modelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
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

              // Account Section
              _buildSectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Free Account'),
                subtitle: const Text('Upgrade to access all features'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Upgrade',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: _handleUpgrade,
              ),
              const Divider(),

              // Preferences Section
              _buildSectionHeader('Preferences'),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch to dark theme'),
                value: _isDarkMode,
                onChanged: _handleThemeChange,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Daily study reminders'),
                value: _notificationsEnabled,
                onChanged: _handleNotificationChange,
              ),
              const Divider(),

              // AI Model Section
              _buildSectionHeader('AI Model'),
              ListTile(
                leading: Icon(
                  Icons.psychology,
                  color: _modelDownloaded
                      ? const Color(0xFF4CAF50)
                      : AppColors.textSecondary,
                ),
                title: const Text('CodeGemma 2B (On-Device)'),
                subtitle: Text(
                  _modelDownloaded
                      ? 'Downloaded — AI generation active'
                      : 'Not downloaded — using template mode',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModelSetupScreen(
                        onSetupComplete: _checkModelStatus,
                      ),
                    ),
                  );
                  _checkModelStatus();
                },
              ),
              const Divider(),

              // Data Management Section
              _buildSectionHeader('Data Management'),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset Progress'),
                subtitle: const Text('Clear all progress data'),
                onTap: _handleResetProgress,
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Clear Bookmarks'),
                subtitle: const Text('Remove all saved bookmarks'),
                onTap: _handleClearBookmarks,
              ),
              const Divider(),

              // About Section
              _buildSectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
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
                child: Text(
                  'Version 1.0.0',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
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
        style: AppTextStyles.heading2.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _handleThemeChange(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    // TODO: Implement theme change
  }

  void _handleNotificationChange(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    // TODO: Implement notification settings
  }

  Future<void> _handleResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
            'Are you sure you want to reset all progress? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
        content: const Text(
            'Are you sure you want to clear all bookmarks? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
          const SnackBar(content: Text('All bookmarks have been cleared')),
        );
      }
    }
  }

  void _handleUpgrade() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Get access to:'),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.check_circle, 'All premium questions'),
            _buildFeatureItem(Icons.check_circle, 'Company-specific questions'),
            _buildFeatureItem(Icons.check_circle, 'Advanced statistics'),
            _buildFeatureItem(Icons.check_circle, 'Ad-free experience'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('MAYBE LATER'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement upgrade flow
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('UPGRADE NOW'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About EatCode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text(
                'A flashcard app to help you master coding interview problems.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Practice problems by category'),
            Text('• Track your progress'),
            Text('• Bookmark favorite problems'),
            Text('• Study solutions'),
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

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This app stores all data locally on your device. '
            'We do not collect or transmit any personal information. '
            'Your progress and bookmarks are stored only on your device.',
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
            Text('Need help? Here are some resources:'),
            SizedBox(height: 16),
            Text('• Check our FAQ section'),
            Text('• Watch tutorial videos'),
            Text('• Contact support'),
            SizedBox(height: 16),
            Text('Email: support@eatcode.app'),
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
