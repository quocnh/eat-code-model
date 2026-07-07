import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import '../services/problem_generator.dart';
import '../services/model_download_service.dart';
import '../models/generated_problem.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import 'model_setup_screen.dart';

class AiProblemScreen extends StatefulWidget {
  final String? initialCategory;

  /// When set the screen auto-generates a problem similar to this one.
  final String? initialProblem;

  const AiProblemScreen({super.key, this.initialCategory, this.initialProblem});

  @override
  State<AiProblemScreen> createState() => _AiProblemScreenState();
}

class _AiProblemScreenState extends State<AiProblemScreen> {
  LlmService? _llmService;
  ProblemGenerator? _generator;
  bool _llmInitialized = false;

  String _selectedCategory = 'Arrays';
  String _selectedDifficulty = 'Medium';
  bool _isGenerating = false;
  bool _isInitializing = true;
  bool _isGemmaMode = false;
  GeneratedProblem? _generatedProblem;
  String _streamBuffer = '';
  String? _errorMessage;

  final List<String> _categories = [
    'Arrays',
    'Strings',
    'Trees',
    'Graphs',
    'Dynamic Programming',
    'Binary Search',
    'Two Pointers',
    'Sliding Window',
    'Stack',
    'Heap',
    'Backtracking',
    'Linked List',
  ];

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      // Find the matching category from the list (handles "Two Pointers" → technique name mapping)
      final match = _categories.firstWhere(
        (c) => c.toLowerCase() == widget.initialCategory!.toLowerCase(),
        orElse: () => _categories.firstWhere(
          (c) =>
              c.toLowerCase().contains(widget.initialCategory!.toLowerCase()) ||
              widget.initialCategory!.toLowerCase().contains(c.toLowerCase()),
          orElse: () => 'Arrays',
        ),
      );
      _selectedCategory = match;
    }
    _initializeLlm();
  }

  @override
  void dispose() {
    // Only dispose TemplateLlmService instances — GemmaLlmService is a
    // process-wide singleton shared with AiChatButton and must not be torn down.
    if (_llmInitialized && _llmService is TemplateLlmService) {
      _llmService!.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeLlm() async {
    // Check if CodeGemma model is downloaded
    final downloadService = ModelDownloadService();
    final modelReady = await downloadService.isModelDownloaded();

    if (modelReady) {
      try {
        final gemmaService = GemmaLlmService();
        await gemmaService.initialize();
        _llmService = gemmaService;
        _isGemmaMode = true;
      } catch (_) {
        // Model file exists but init failed — fall back to templates
        final fallbackService = TemplateLlmService();
        await fallbackService.initialize();
        _llmService = fallbackService;
        _isGemmaMode = false;
      }
    } else {
      final fallbackService = TemplateLlmService();
      await fallbackService.initialize();
      _llmService = fallbackService;
      _isGemmaMode = false;
    }

    _generator = ProblemGenerator(_llmService!);
    _llmInitialized = true;
    if (mounted) {
      setState(() => _isInitializing = false);
      // Auto-generate immediately when a similar-problem context was provided
      if (widget.initialProblem != null) {
        _generateProblem();
      }
    }
  }

  Future<void> _openModelSetup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelSetupScreen(
          onSetupComplete: () {
            // Reset the singleton so _attempted / _initFuture are cleared
            // before _initializeLlm() retries the on-device model.
            GemmaLlmService().reset();
            setState(() => _isInitializing = true);
            _initializeLlm();
          },
        ),
      ),
    );
  }

  Future<void> _generateProblem() async {
    setState(() {
      _isGenerating = true;
      _streamBuffer = '';
      _generatedProblem = null;
      _errorMessage = null;
    });

    final similarProblem = widget.initialProblem;

    try {
      // Stream tokens for the live preview
      final stream = similarProblem != null
          ? _generator!.generateSimilarProblemStream(
              problemName: similarProblem,
              category: _selectedCategory,
              difficulty: _selectedDifficulty,
            )
          : _generator!.generateProblemStream(
              category: _selectedCategory,
              difficulty: _selectedDifficulty,
            );

      await for (final chunk in stream) {
        if (mounted) {
          setState(() => _streamBuffer += chunk);
        }
      }

      // Parse the buffered output into a structured problem
      final problem = similarProblem != null
          ? await _generator!.generateSimilarProblem(
              problemName: similarProblem,
              category: _selectedCategory,
              difficulty: _selectedDifficulty,
            )
          : await _generator!.generateProblem(
              category: _selectedCategory,
              difficulty: _selectedDifficulty,
            );

      if (mounted) {
        setState(() {
          _generatedProblem = problem;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Generation failed: $e';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _saveToFlashcards() async {
    if (_generatedProblem == null) return;
    try {
      final db = DatabaseHelper();
      final flashcard = Flashcard(
        title: _generatedProblem!.title,
        content: _generatedProblem!.toMarkdownContent(),
        difficulty: _generatedProblem!.difficulty,
        category: _generatedProblem!.category,
        isPremium: false,
      );
      await db.insertFlashcard(flashcard);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problem saved to your flashcard deck!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'AI Problem Generator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isInitializing
          ? _buildInitializingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.initialProblem != null) ...[
                    _buildSimilarProblemBanner(widget.initialProblem!),
                    const SizedBox(height: 12),
                  ],
                  _buildModelStatusCard(),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  _buildDifficultySelector(),
                  const SizedBox(height: 20),
                  _buildGenerateButton(),
                  const SizedBox(height: 20),
                  _buildOutputArea(),
                ],
              ),
            ),
    );
  }

  Widget _buildSimilarProblemBanner(String problemName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: Colors.purple, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Similar Problem Mode',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Generating a problem inspired by: $problemName',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Initializing AI model…',
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isGemmaMode
            ? AppColors.primary.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isGemmaMode
              ? AppColors.primary.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isGemmaMode ? Icons.memory : Icons.description_outlined,
            color: _isGemmaMode ? AppColors.primary : Colors.orange[700],
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isGemmaMode
                      ? 'AI Problem Engine (On-device)'
                      : 'Template Mode',
                  style:
                      AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _isGemmaMode
                      ? 'Local neural network — no internet needed'
                      : 'Curated templates active. Tap to enable AI.',
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
          if (!_isGemmaMode)
            TextButton(
              onPressed: _openModelSetup,
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Setup AI',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.primary : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    final colors = {
      'Easy': AppColors.success,
      'Medium': AppColors.warning,
      'Hard': AppColors.error,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: _difficulties.map((diff) {
            final selected = _selectedDifficulty == diff;
            final color = colors[diff]!;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: diff != _difficulties.last ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDifficulty = diff),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? color : color.withOpacity(0.3),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      diff,
                      style: TextStyle(
                        color: selected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateProblem,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _isGenerating
              ? 'Generating…'
              : (widget.initialProblem != null
                  ? 'Generate Similar Problem'
                  : 'Generate Problem'),
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }

  Widget _buildOutputArea() {
    if (_errorMessage != null) {
      return _buildErrorCard();
    }
    if (_isGenerating) {
      return _buildStreamingPreview();
    }
    if (_generatedProblem != null) {
      return _buildProblemCard();
    }
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.psychology_outlined,
              size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Select a category and difficulty,\nthen tap Generate Problem.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Generating…',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            _streamBuffer.isEmpty ? 'Waiting for model…' : _streamBuffer,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generation Failed',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_errorMessage!, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemCard() {
    final problem = _generatedProblem!;
    final diffColors = {
      'Easy': AppColors.success,
      'Medium': AppColors.warning,
      'Hard': AppColors.error,
    };
    final diffColor = diffColors[problem.difficulty] ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        problem.title,
                        style: AppTextStyles.heading2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: diffColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        problem.difficulty,
                        style: TextStyle(
                          color: diffColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        problem.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                _buildProblemSection(
                  label: 'Description',
                  child: Text(problem.description, style: AppTextStyles.body1),
                ),

                // Examples
                if (problem.examples.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildProblemSection(
                    label: 'Examples',
                    child: Column(
                      children: problem.examples.map((ex) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ex,
                            style: AppTextStyles.body2.copyWith(
                              fontFamily: 'Courier',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Constraints
                if (problem.constraints.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildProblemSection(
                    label: 'Constraints',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: problem.constraints.map((c) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              Expanded(
                                child: Text(c, style: AppTextStyles.body2),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // ── Optimized solution ───────────────────────────────────
                if (problem.solutionApproach.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildProblemSection(
                    label: '⚡ Optimized Approach',
                    child: Text(
                      problem.solutionApproach,
                      style: AppTextStyles.body1,
                    ),
                  ),
                ],

                if (problem.code.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildProblemSection(
                    label: 'Optimized Code',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          problem.code,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            color: Color(0xFFCDD6F4),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Complexity
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildComplexityBadge(
                        'Time',
                        problem.timeComplexity,
                        Icons.timer_outlined,
                        const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildComplexityBadge(
                        'Space',
                        problem.spaceComplexity,
                        Icons.memory_outlined,
                        const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),

                // ── Brute force solution (when available) ────────────────
                if (problem.bruteForceCode.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildProblemSection(
                    label: '🐌 Brute Force Approach',
                    child: Text(
                      problem.bruteForceApproach.isNotEmpty
                          ? problem.bruteForceApproach
                          : 'Naive approach using nested iteration.',
                      style: AppTextStyles.body1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProblemSection(
                    label: 'Brute Force Code',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1B1B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          problem.bruteForceCode,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            color: Color(0xFFFFCDD2),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveToFlashcards,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text(
                      'Save to Flashcards',
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemSection({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildComplexityBadge(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
