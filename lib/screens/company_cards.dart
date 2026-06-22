import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../models/progress.dart';
import '../services/problem_generator.dart';
import '../services/llm_service.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
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
  final Map<String, bool> _generating = {};

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

  Future<void> _generateMore(String company) async {
    setState(() => _generating[company] = true);

    try {
      final service = TemplateLlmService();
      await service.initialize();
      final generator = ProblemGenerator(service);

      // Generate one problem per difficulty to keep it quick
      for (final difficulty in ['Easy', 'Medium', 'Hard']) {
        final problem = await generator.generateCompanyProblem(
          company: company,
          difficulty: difficulty,
        );

        final flashcard = Flashcard(
          title: problem.title,
          content: problem.toMarkdownContent(),
          difficulty: problem.difficulty,
          category: problem.category,
          company: company,
          isPremium: false,
          createdAt: DateTime.now(),
        );

        final id = await _dbHelper.insertFlashcard(flashcard);
        await _dbHelper.updateProgress(Progress(
          flashcardId: id,
          isCompleted: false,
          confidenceLevel: 0,
          timesReviewed: 0,
        ));
      }

      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('3 new $company problems generated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate problems: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating[company] = false);
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
    final emoji = profile?['emoji'] as String? ?? '🏢';
    final note = profile?['note'] as String? ?? '';
    final stats =
        _difficultyStats[company] ?? {'Easy': 0, 'Medium': 0, 'Hard': 0};
    final total = _totalCounts[company] ?? 0;
    final isGenerating = _generating[company] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isGenerating
            ? null
            : () async {
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
              // Header row
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
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
              Row(
                children: [
                  _buildDifficultyChip('Easy', stats['Easy'] ?? 0),
                  const SizedBox(width: 6),
                  _buildDifficultyChip('Medium', stats['Medium'] ?? 0),
                  const SizedBox(width: 6),
                  _buildDifficultyChip('Hard', stats['Hard'] ?? 0),
                ],
              ),

              const SizedBox(height: 14),

              // Get More button — tap card body to practice
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        isGenerating ? null : () => _generateMore(company),
                    icon: isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: Text(isGenerating ? 'Loading…' : 'Get More'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
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
