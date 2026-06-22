import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../models/progress.dart';
import '../services/problem_generator.dart';
import '../services/llm_service.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import '../widgets/markdown_syntax_highlighter.dart';

/// Shows all AI-generated flashcards for a single company.
/// Users can flip between question and solution, bookmark cards,
/// and generate more problems on demand.
class CompanyProblemScreen extends StatefulWidget {
  final String company;

  const CompanyProblemScreen({super.key, required this.company});

  @override
  State<CompanyProblemScreen> createState() => _CompanyProblemScreenState();
}

class _CompanyProblemScreenState extends State<CompanyProblemScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Flashcard> _cards = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _dbHelper.getFlashcardsByCompany(widget.company);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateMore() async {
    setState(() => _isGenerating = true);

    try {
      final service = TemplateLlmService();
      await service.initialize();
      final generator = ProblemGenerator(service);

      for (final difficulty in ['Easy', 'Medium', 'Hard']) {
        final problem = await generator.generateCompanyProblem(
          company: widget.company,
          difficulty: difficulty,
        );

        final flashcard = Flashcard(
          title: problem.title,
          content: problem.toMarkdownContent(),
          difficulty: problem.difficulty,
          category: problem.category,
          company: widget.company,
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

      await _loadCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('3 new problems generated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _toggleBookmark(Flashcard card) async {
    if (card.id == null) return;
    await _dbHelper.toggleBookmark(card.id!);
    await _loadCards();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No problems yet', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Generate your first set of ${widget.company} problems',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateMore,
              icon: const Icon(Icons.add),
              label: const Text('Generate Problems'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = companyProfiles[widget.company];
    final emoji = profile?['emoji'] as String? ?? '🏢';

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('${widget.company} Problems'),
        ]),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          Text('${_cards.length} problems',
                              style: AppTextStyles.body2),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _isGenerating ? null : _generateMore,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_circle_outline,
                                    size: 18),
                            label:
                                Text(_isGenerating ? 'Loading…' : 'Get More'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Scrollable problem list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _cards.length,
                        itemBuilder: (_, i) => _ProblemCardItem(
                          key: ValueKey(_cards[i].id),
                          card: _cards[i],
                          company: widget.company,
                          onBookmarkToggled: () => _toggleBookmark(_cards[i]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Self-managing problem card for the list view
// ---------------------------------------------------------------------------

class _ProblemCardItem extends StatefulWidget {
  final Flashcard card;
  final String company;
  final VoidCallback onBookmarkToggled;

  const _ProblemCardItem({
    super.key,
    required this.card,
    required this.company,
    required this.onBookmarkToggled,
  });

  @override
  State<_ProblemCardItem> createState() => _ProblemCardItemState();
}

class _ProblemCardItemState extends State<_ProblemCardItem> {
  bool _showSolution = false;

  Color _diffColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.easy;
      case 'hard':
        return AppColors.hard;
      default:
        return AppColors.medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final content =
        _showSolution ? card.getSolutionContent() : card.getQuestionContent();

    return GestureDetector(
      onTap: () => setState(() => _showSolution = !_showSolution),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Difficulty
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _diffColor(card.difficulty).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      card.difficulty,
                      style: TextStyle(
                        color: _diffColor(card.difficulty),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Category
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      card.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bookmark — absorbed so it doesn't trigger card flip
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onBookmarkToggled(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        card.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: card.isBookmarked
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Q / S pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _showSolution
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showSolution ? Icons.lightbulb : Icons.help_outline,
                          size: 13,
                          color: _showSolution
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showSolution ? 'Solution' : 'Question',
                          style: TextStyle(
                            color: _showSolution
                                ? AppColors.success
                                : AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(card.title, style: AppTextStyles.heading2),
            ),
            // Markdown content — MarkdownBody expands to natural height
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: MarkdownBody(
                data: content.isNotEmpty
                    ? content
                    : '_Tap to reveal ${_showSolution ? "question" : "solution"}_',
                builders: {'code': SyntaxHighlightMarkdownBuilder()},
                styleSheet: MarkdownStyles.getStyleSheet(context),
                shrinkWrap: true,
              ),
            ),
            // Tap hint
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app,
                      size: 12,
                      color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to ${_showSolution ? "see question" : "reveal solution"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
