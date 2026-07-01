import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../models/generated_problem.dart';
import '../services/llm_service.dart';
import '../services/problem_generator.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import '../widgets/company_logo.dart';
import '../widgets/markdown_syntax_highlighter.dart';

/// Shows all AI-generated flashcards for a single company as a clean,
/// title-only list. Tapping a row opens a detail sheet with the full
/// question, solution and bookmark controls.
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

  // AI generation
  ProblemGenerator? _generator;

  @override
  void initState() {
    super.initState();
    _loadCards();
    _initGenerator();
  }

  Future<void> _initGenerator() async {
    final svc = GemmaLlmService();
    await svc.initialize().catchError((_) {});
    if (mounted) {
      setState(() => _generator = ProblemGenerator(svc));
    }
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

  Future<void> _toggleBookmark(Flashcard card) async {
    if (card.id == null) return;
    await _dbHelper.toggleBookmark(card.id!);
    await _loadCards();
  }

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

  void _openProblemDetail(Flashcard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProblemDetailSheet(
        card: card,
        onBookmarkToggled: () async {
          await _toggleBookmark(card);
          // Pop and reopen with the refreshed card so the icon updates.
          if (mounted) {
            Navigator.of(context).pop();
            final updated = _cards.firstWhere(
              (c) => c.id == card.id,
              orElse: () => card,
            );
            _openProblemDetail(updated);
          }
        },
      ),
    );
  }

  void _showGenerateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenerateSheet(
        company: widget.company,
        generator: _generator,
        onSaved: _loadCards,
      ),
    );
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
              'Problems for ${widget.company} will appear here once generated.',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemRow(Flashcard card, int index) {
    return InkWell(
      onTap: () => _openProblemDetail(card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Numeric index badge
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title only
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _diffColor(card.difficulty).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.difficulty,
                          style: TextStyle(
                            color: _diffColor(card.difficulty),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          card.category,
                          style: AppTextStyles.body2.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (card.isBookmarked)
              Icon(Icons.bookmark, size: 18, color: AppColors.warning),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CompanyLogo(company: widget.company, size: 28),
          const SizedBox(width: 10),
          Text('${widget.company} Problems'),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerateSheet,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCards,
                  child: Column(
                    children: [
                      // Summary row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Row(
                          children: [
                            Text('${_cards.length} problems',
                                style: AppTextStyles.body2),
                            const Spacer(),
                            Text('Tap to view',
                                style: AppTextStyles.body2.copyWith(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                )),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _cards.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) => _buildProblemRow(_cards[i], i),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Problem detail bottom sheet — shows full question/solution with toggle
// ---------------------------------------------------------------------------

class _ProblemDetailSheet extends StatefulWidget {
  final Flashcard card;
  final VoidCallback onBookmarkToggled;

  const _ProblemDetailSheet({
    required this.card,
    required this.onBookmarkToggled,
  });

  @override
  State<_ProblemDetailSheet> createState() => _ProblemDetailSheetState();
}

class _ProblemDetailSheetState extends State<_ProblemDetailSheet> {
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

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _diffColor(card.difficulty).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.difficulty,
                      style: TextStyle(
                        color: _diffColor(card.difficulty),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      card.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: card.isBookmarked
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    onPressed: widget.onBookmarkToggled,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(card.title, style: AppTextStyles.heading1),
              ),
            ),
            // Question/Solution toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentedToggle(
                      selected: _showSolution,
                      onChanged: (v) => setState(() => _showSolution = v),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Markdown content (scrollable)
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: MarkdownBody(
                  data: _showSolution
                      ? (card.getSolutionContent().isNotEmpty
                          ? card.getSolutionContent()
                          : card.solution)
                      : (card.getQuestionContent().isNotEmpty
                          ? card.getQuestionContent()
                          : card.question),
                  selectable: true,
                  builders: {'code': SyntaxHighlightMarkdownBuilder()},
                  styleSheet: MarkdownStyles.getStyleSheet(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final bool selected; // false = question, true = solution
  final ValueChanged<bool> onChanged;

  const _SegmentedToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSegment('Question', Icons.help_outline, !selected,
              () => onChanged(false), AppColors.primary),
          _buildSegment('Solution', Icons.lightbulb, selected,
              () => onChanged(true), AppColors.success),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, IconData icon, bool active,
      VoidCallback onTap, Color activeColor) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? activeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generate company-style problem sheet
// ---------------------------------------------------------------------------

class _GenerateSheet extends StatefulWidget {
  final String company;
  final ProblemGenerator? generator;
  final VoidCallback onSaved;

  const _GenerateSheet({
    required this.company,
    required this.generator,
    required this.onSaved,
  });

  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  String _difficulty = 'Medium';
  bool _isGenerating = false;
  bool _isSaving = false;
  GeneratedProblem? _result;
  String? _error;
  String _streamBuffer = '';

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

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

  Future<void> _generate() async {
    if (widget.generator == null) return;
    setState(() {
      _isGenerating = true;
      _result = null;
      _error = null;
      _streamBuffer = '';
    });

    try {
      // Stream tokens for a live preview
      final stream = widget.generator!.generateCompanyProblemStream(
        company: widget.company,
        difficulty: _difficulty,
      );
      await for (final chunk in stream) {
        if (mounted) setState(() => _streamBuffer += chunk);
      }

      // Parse the completed response into a structured problem
      final problem = await widget.generator!.generateCompanyProblem(
        company: widget.company,
        difficulty: _difficulty,
      );
      if (mounted) {
        setState(() {
          _result = problem;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Generation failed. Please try again.';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _saveToCompany() async {
    if (_result == null) return;
    setState(() => _isSaving = true);
    try {
      final db = DatabaseHelper();
      final flashcard = Flashcard(
        title: _result!.title,
        content: _result!.toMarkdownContent(),
        difficulty: _result!.difficulty,
        category: _result!.category,
        company: widget.company,
        isPremium: false,
      );
      await db.insertFlashcard(flashcard);
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to ${widget.company} problems!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = companyProfiles[widget.company];
    final aiMode = widget.generator != null && GemmaLlmService().isModelLoaded;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Generate ${widget.company}-style Problem',
                    style: AppTextStyles.heading2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Mode badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: aiMode
                        ? AppColors.success.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aiMode ? 'On-device AI' : 'Template',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          aiMode ? AppColors.success : Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                profile['note'] as String,
                style: AppTextStyles.body2
                    .copyWith(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          // Difficulty selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Difficulty:', style: AppTextStyles.body2),
                const SizedBox(width: 12),
                ..._difficulties.map((d) {
                  final selected = _difficulty == d;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _isGenerating
                          ? null
                          : () => setState(() => _difficulty = d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? _diffColor(d)
                              : _diffColor(d).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : _diffColor(d),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Generate button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isGenerating || widget.generator == null)
                    ? null
                    : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isGenerating ? 'Generating…' : 'Generate Problem'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // Result area
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.error),
                          textAlign: TextAlign.center),
                    ),
                  )
                : _result != null
                    ? _buildResultView()
                    : _streamBuffer.isNotEmpty
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _streamBuffer,
                              style: AppTextStyles.body2
                                  .copyWith(fontFamily: 'monospace'),
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 48,
                                      color: AppColors.textSecondary
                                          .withOpacity(0.3)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Choose a difficulty and tap Generate.',
                                    style: AppTextStyles.body2,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final p = _result!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + tags
                Text(p.title,
                    style: AppTextStyles.heading1.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _diffColor(p.difficulty).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.difficulty,
                        style: TextStyle(
                            color: _diffColor(p.difficulty),
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.category,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(p.description, style: AppTextStyles.body2),
                if (p.timeComplexity.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '⏱ Time: ${p.timeComplexity}   💾 Space: ${p.spaceComplexity}',
                    style: AppTextStyles.body2.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Save button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveToCompany,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                  _isSaving ? 'Saving…' : 'Add to ${widget.company} Problems'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
