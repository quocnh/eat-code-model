import 'package:flutter/material.dart';
import 'dart:async';
import '../styles/colors.dart';
import '../styles/text_styles.dart';

class PremiumUpgradeDialog extends StatefulWidget {
  const PremiumUpgradeDialog({super.key});

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog> {
  bool _isProcessing = false;
  String? _error;
  Timer? _processingTimer;

  @override
  void dispose() {
    _processingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleUpgrade() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Simulate payment processing
      _processingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            // Show success dialog
            _showSuccessDialog();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Failed to process upgrade. Please try again.';
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Upgrade Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome to Premium! You now have access to:'),
            const SizedBox(height: 16),
            _buildSuccessFeature(Icons.business, 'Company-specific questions'),
            _buildSuccessFeature(Icons.timeline, 'Advanced progress tracking'),
            _buildSuccessFeature(Icons.star, 'Premium content'),
            _buildSuccessFeature(Icons.block, 'Ad-free experience'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Close both dialogs and return to main screen
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildPricingOption(
      String title, String price, String interval, List<String> features) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primary,
                  fontSize: 32,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  interval,
                  style: AppTextStyles.body2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: AppTextStyles.body2,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: AppTextStyles.heading1,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPricingOption(
                'One-Time Payment',
                '\$5',
                '/year',
                [
                  'New EatCode cards updated',
                  'All premium questions',
                  'Company-specific questions',
                  'Advanced progress tracking',
                  'Ad-free experience',
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _handleUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Upgrade Now'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
