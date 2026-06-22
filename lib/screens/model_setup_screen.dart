import 'package:flutter/material.dart';
import '../services/model_download_service.dart';

class ModelSetupScreen extends StatefulWidget {
  final VoidCallback? onSetupComplete;
  const ModelSetupScreen({super.key, this.onSetupComplete});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  final _downloadService = ModelDownloadService();

  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isCheckingStatus = true;
  double _progress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    setState(() => _isCheckingStatus = true);
    final downloaded = await _downloadService.isModelDownloaded();
    setState(() {
      _isDownloaded = downloaded;
      _isCheckingStatus = false;
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    await _downloadService.downloadModel(
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
          });
          widget.onSetupComplete?.call();
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = err;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isCheckingStatus
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildHeader(),
                    const Spacer(flex: 3),
                    _buildActionArea(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const Icon(Icons.psychology_outlined,
              size: 40, color: Colors.white),
        ),
        const SizedBox(height: 28),
        const Text(
          'Enable AI Generation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _isDownloaded
              ? 'Your AI model is installed and ready.'
              : 'A one-time setup is required to generate\npersonalized coding problems on-device.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 15,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionArea() {
    if (_isDownloaded) return _buildReadyState();
    if (_isDownloading) return _buildDownloadingState();
    return _buildIdleState();
  }

  Widget _buildIdleState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFE53935), size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Setup failed. Please try again.',
                    style: TextStyle(color: Color(0xFFE53935), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Set Up Now',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Requires a one-time internet connection.\nWorks fully offline after setup.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 12,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDownloadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Setting up your AI model…',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Keep the app open. This may take a few minutes.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReadyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 20),
            const SizedBox(width: 8),
            Text(
              'AI model is ready',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              widget.onSetupComplete?.call();
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
