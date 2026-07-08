import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../data/quiz_data.dart';
import '../services/path_progress_service.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';

/// Presents a 3-question MCQ quiz for a technique.
/// Passing (≥ 2/3 correct) calls [PathProgressService.markMastered].
class KnowledgeTestScreen extends StatefulWidget {
  final String techniqueId;
  final String techniqueName;
  final Color pathColor;

  const KnowledgeTestScreen({
    super.key,
    required this.techniqueId,
    required this.techniqueName,
    required this.pathColor,
  });

  @override
  State<KnowledgeTestScreen> createState() => _KnowledgeTestScreenState();
}

class _KnowledgeTestScreenState extends State<KnowledgeTestScreen> {
  late final List<QuizQuestion> _questions;
  final List<int?> _selected = []; // chosen option index per question
  bool _submitted = false;

  static const int _passMark = 2; // must get at least this many correct

  @override
  void initState() {
    super.initState();
    _questions = QuizData.forTechnique(widget.techniqueId);
    _selected.addAll(List.filled(_questions.length, null));
  }

  int get _correctCount => List.generate(_questions.length, (i) {
        final sel = _selected[i];
        if (sel == null) return 0;
        return sel == _questions[i].correctIndex ? 1 : 0;
      }).fold(0, (a, b) => a + b);

  bool get _passed => _correctCount >= _passMark;

  bool get _allAnswered => _selected.every((s) => s != null);

  void _submit() {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions first.')),
      );
      return;
    }
    setState(() => _submitted = true);
    if (_passed) {
      PathProgressService().markMastered(widget.techniqueId);
    }
  }

  void _retry() {
    setState(() {
      _submitted = false;
      for (int i = 0; i < _selected.length; i++) {
        _selected[i] = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.pathColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Knowledge Check',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.techniqueName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _questions.isEmpty
          ? _buildNoQuiz()
          : _submitted
              ? _buildResults()
              : _buildQuiz(),
    );
  }

  // ── No quiz available ──────────────────────────────────────────────────────

  Widget _buildNoQuiz() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No quiz available for this topic yet.',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Quiz questions ─────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.pathColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.pathColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.quiz, color: widget.pathColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_questions.length} questions',
                      style: TextStyle(
                        color: widget.pathColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Score ≥ $_passMark/${_questions.length} to mark as mastered',
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Questions
        ...List.generate(_questions.length, (qi) {
          final q = _questions[qi];
          return _buildQuestionCard(qi, q);
        }),

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _allAnswered ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.pathColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: widget.pathColor.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Submit Answers',
              style: AppTextStyles.buttonText,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildQuestionCard(int qi, QuizQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.pathColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${qi + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(q.question, style: AppTextStyles.body1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(q.options.length, (oi) {
              final selected = _selected[qi] == oi;
              return GestureDetector(
                onTap: () {
                  setState(() => _selected[qi] = oi);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? widget.pathColor.withOpacity(0.12)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? widget.pathColor
                          : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? widget.pathColor : Colors.grey.shade400,
                            width: 2,
                          ),
                          color: selected ? widget.pathColor : Colors.transparent,
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(q.options[oi], style: AppTextStyles.body2),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final color = widget.pathColor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _passed
                  ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                  : [const Color(0xFFC62828), const Color(0xFFEF5350)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_passed ? AppColors.primary : AppColors.error).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _passed ? '🎉 Mastered!' : '😅 Not Yet',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_correctCount / ${_questions.length} correct',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _passed
                    ? '${widget.techniqueName} marked as mastered ✓'
                    : 'Need $_passMark/${_questions.length} to pass — try again!',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Per-question review
        Text('Review', style: AppTextStyles.heading2.copyWith(fontSize: 17)),
        const SizedBox(height: 12),

        ...List.generate(_questions.length, (qi) {
          final q = _questions[qi];
          final sel = _selected[qi];
          final isCorrect = sel == q.correctIndex;
          final reviewColor = isCorrect ? AppColors.success : AppColors.error;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: reviewColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: reviewColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(q.question, style: AppTextStyles.body1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Options with highlight
                ...List.generate(q.options.length, (oi) {
                  final isCorrectOpt = oi == q.correctIndex;
                  final isChosen = oi == sel;
                  Color optBg = Colors.transparent;
                  Color optBorder = Colors.grey.shade200;
                  Color optText = AppColors.textPrimary;

                  if (isCorrectOpt) {
                    optBg = AppColors.success.withOpacity(0.1);
                    optBorder = AppColors.success;
                    optText = AppColors.success;
                  } else if (isChosen && !isCorrect) {
                    optBg = AppColors.error.withOpacity(0.08);
                    optBorder = AppColors.error;
                    optText = AppColors.error;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: optBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: optBorder),
                    ),
                    child: Row(
                      children: [
                        if (isCorrectOpt)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.check, size: 14, color: AppColors.success),
                          )
                        else if (isChosen && !isCorrect)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.close, size: 14, color: AppColors.error),
                          ),
                        Expanded(
                          child: Text(
                            q.options[oi],
                            style: TextStyle(
                              color: optText,
                              fontSize: 13,
                              fontWeight: isCorrectOpt
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: color, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          q.explanation,
                          style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Action buttons
        if (_passed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.star),
              label: const Text('Back to Path', style: AppTextStyles.buttonText),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Study'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ),
            ],
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}
