import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/problem_generator.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import '../widgets/company_logo.dart';
import 'company_problem_screen.dart';

class CompanyCards extends StatefulWidget {
  const CompanyCards({super.key});

  @override
  State<CompanyCards> createState() => _CompanyCardsState();
}

class _CompanyCardsState extends State<CompanyCards> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, Map<String, int>> _difficultyStats = {};
  Map<String, int> _totalCounts = {};
  bool _isLoading = true;

  // Ordered list matching companyProfiles
  static const _companies = [
    'Google',
    'Amazon',
    'Meta',
    'Microsoft',
    'Apple',
    'Netflix',
    'Uber',
    'Airbnb',
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = <String, Map<String, int>>{};
      final totals = <String, int>{};

      for (final company in _companies) {
        final s = await _dbHelper.getDifficultyCountByCompany(company);
        stats[company] = s;
        totals[company] = s.values.fold(0, (a, b) => a + b);
      }

      setState(() {
        _difficultyStats = stats;
        _totalCounts = totals;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.easy;
      case 'medium':
        return AppColors.medium;
      case 'hard':
        return AppColors.hard;
      default:
        return AppColors.medium;
    }
  }

  Widget _buildDifficultyChip(String difficulty, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDifficultyColor(difficulty).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $difficulty',
        style: AppTextStyles.chipText.copyWith(
          color: _getDifficultyColor(difficulty),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCompanyCard(String company) {
    final profile = companyProfiles[company];
    final note = profile?['note'] as String? ?? '';
    final stats =
        _difficultyStats[company] ?? {'Easy': 0, 'Medium': 0, 'Hard': 0};
    final total = _totalCounts[company] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompanyProblemScreen(company: company),
            ),
          );
          _loadStats();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row — real-style brand logo
              Row(
                children: [
                  CompanyLogo(company: company, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(company, style: AppTextStyles.heading2),
                        Text(
                          '$total AI-generated problems',
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: AppColors.textSecondary.withOpacity(0.6)),
                ],
              ),

              // Interview style note
              if (note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note,
                  style: AppTextStyles.body2.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Difficulty chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildDifficultyChip('Easy', stats['Easy'] ?? 0),
                  _buildDifficultyChip('Medium', stats['Medium'] ?? 0),
                  _buildDifficultyChip('Hard', stats['Hard'] ?? 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Interviews'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: Column(
                children: [
                  // Banner
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "All problems are AI-generated originals in the style of each company's interviews.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Company list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _companies.length,
                      itemBuilder: (_, i) => _buildCompanyCard(_companies[i]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
