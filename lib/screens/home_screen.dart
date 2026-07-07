import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';
import 'dart:async';
import 'dart:math';
import '../widgets/ai_chat_button.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/category_chip.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../models/progress.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import 'main_navigation_screen.dart';
import '../widgets/markdown_syntax_highlighter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _selectedCategoryIndex = 0;
  bool _isFlipped = false;
  Flashcard? _currentFlashcard;
  List<Flashcard> _flashcards = [];
  int _currentCardIndex = 0;
  bool _isTimerActive = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  final Random _random = Random();

  final List<String> _categories = [
    'All',
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

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refreshCards() async {
    await _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    String? category = _selectedCategoryIndex == 0
        ? null
        : _categories[_selectedCategoryIndex];

    final cards = await _dbHelper.getFlashcards(
      category: category,
      excludeCompleted: true,
    );

    if (mounted) {
      setState(() {
        _flashcards = cards;
        _currentCardIndex = 0;
        _currentFlashcard = cards.isNotEmpty ? cards[0] : null;
        _isFlipped = false;
      });
    }
  }

  void _handleCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _isFlipped = false;
      _stopTimer();
    });
    _loadFlashcards();
  }

  Future<void> _toggleBookmark() async {
    if (_currentFlashcard?.id != null) {
      await _dbHelper.toggleBookmark(_currentFlashcard!.id!);
      // Get reference to MainNavigationScreen state and refresh bookmarks
      // Reload current screen's cards
      await _loadFlashcards();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = true;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = false;
    });
  }

  void _toggleTimer() {
    if (_isTimerActive) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Card Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Current streak: ${_currentCardIndex + 1}/${_flashcards.length}'),
            const SizedBox(height: 8),
            Text('Time spent: ${_elapsedSeconds}s'),
            const SizedBox(height: 8),
            Text('Category: ${_currentFlashcard?.category}'),
            const SizedBox(height: 8),
            Text('Difficulty: ${_currentFlashcard?.difficulty}'),
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

  void _navigateToCard(int index) {
    if (index >= 0 && index < _flashcards.length) {
      setState(() {
        _currentCardIndex = index;
        _currentFlashcard = _flashcards[index];
        _isFlipped = false;
      });
      if (_currentFlashcard?.id != null) {
        _dbHelper.updateLastViewed(_currentFlashcard!.id!);
      }
    }
  }

  void _handlePreviousCard() {
    if (_currentCardIndex > 0) {
      _navigateToCard(_currentCardIndex - 1);
    }
  }

  void _handleNextCard() {
    if (_currentCardIndex < _flashcards.length - 1) {
      _navigateToCard(_currentCardIndex + 1);
    }
  }

  void _handleRandomCard() {
    if (_flashcards.isEmpty) return;
    if (_flashcards.length == 1) {
      _navigateToCard(0);
      return;
    }
    int randomIndex;
    do {
      randomIndex = _random.nextInt(_flashcards.length);
    } while (randomIndex == _currentCardIndex);
    _navigateToCard(randomIndex);
  }

  void _showAllProblems() {
    if (_flashcards.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
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
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.list_alt,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All problems (${_flashcards.length})',
                        style: AppTextStyles.heading2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              if (_selectedCategoryIndex != 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _categories[_selectedCategoryIndex],
                        style: AppTextStyles.chipText.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              const Divider(height: 1),
              // Problem list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _flashcards.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, index) {
                    final card = _flashcards[index];
                    final isCurrent = index == _currentCardIndex;
                    return ListTile(
                      dense: true,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _navigateToCard(index);
                      },
                      leading: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color:
                                isCurrent ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        card.title,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight:
                              isCurrent ? FontWeight.w600 : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(card.difficulty)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                card.difficulty,
                                style: TextStyle(
                                  color: _getDifficultyColor(card.difficulty),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                card.category,
                                style: AppTextStyles.body2
                                    .copyWith(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: card.isBookmarked
                          ? Icon(Icons.bookmark,
                              size: 18, color: AppColors.warning)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshProgressScreen() async {
    // Pop back to the main navigation screen
    while (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Navigate to progress screen to force a refresh
    await Navigator.of(context).pushNamed(AppRoutes.progress);

    // Pop back to where we were
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _markCardAsSolved() async {
    if (_currentFlashcard?.id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Solved'),
        content: const Text(
            'Are you sure you want to mark this card as solved? It will be moved to your progress section.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('MARK AS SOLVED'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final progress = Progress(
      flashcardId: _currentFlashcard!.id!,
      isCompleted: true,
      confidenceLevel: 5,
      timesReviewed: 1,
      lastReviewedAt: DateTime.now(),
    );

    await _dbHelper.updateProgress(progress);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_currentFlashcard!.title} marked as solved!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      final mainNavigationState =
          context.findAncestorStateOfType<MainNavigationScreenState>();
      if (mainNavigationState != null) {
        final progressKey = mainNavigationState.progressKey;
        progressKey.currentState?.refreshProgress();
      }
    }

    // Reload the flashcards to update the current view
    await _loadFlashcards();

    if (_flashcards.isEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Category Completed!'),
          content: Text(
            'Congratulations! You\'ve solved all cards in the "${_categories[_selectedCategoryIndex]}" category!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_flashcards.length, (index) {
        return Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index == _currentCardIndex
                  ? AppColors.primary
                  : AppColors.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMarkdownBody(String data) {
    return MarkdownBody(
      data: data,
      selectable: true,
      builders: {
        'code': SyntaxHighlightMarkdownBuilder(),
      },
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.body1,
        h1: AppTextStyles.heading1,
        h2: AppTextStyles.heading2,
        strong: const TextStyle(fontWeight: FontWeight.w600),
        em: const TextStyle(fontStyle: FontStyle.italic),
        listBullet: AppTextStyles.body1,
        blockquote: AppTextStyles.body1.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        code: GoogleFonts.firaCode(
          backgroundColor: Colors.grey[200],
          fontSize: 14,
        ),
        codeblockPadding: const EdgeInsets.all(8),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: CategoryList(
                    categories: _categories,
                    selectedIndex: _selectedCategoryIndex,
                    onSelected: _handleCategorySelected,
                  ),
                ),
                if (_flashcards.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildProgressIndicator(),
                  ),
                if (_currentFlashcard != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () => setState(() => _isFlipped = !_isFlipped),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getDifficultyColor(
                                              _currentFlashcard!.difficulty)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _currentFlashcard!.difficulty,
                                      style: AppTextStyles.chipText.copyWith(
                                        color: _getDifficultyColor(
                                            _currentFlashcard!.difficulty),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (_currentFlashcard!.company != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Text(
                                            _currentFlashcard!.company!,
                                            style: AppTextStyles.body2.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      IconButton(
                                        icon: Icon(
                                          _currentFlashcard!.isBookmarked
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: _currentFlashcard!.isBookmarked
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                        onPressed: _toggleBookmark,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentFlashcard!.title,
                                style: AppTextStyles.heading1,
                              ),
                              const SizedBox(height: 16),
                              _buildMarkdownBody(
                                _isFlipped
                                    ? _currentFlashcard!.solution
                                    : _currentFlashcard!.question,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  _isFlipped
                                      ? 'Tap to see question'
                                      : 'Tap to see solution',
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_currentFlashcard == null)
                  const Expanded(
                    child: Center(
                      child: Text('No flashcards available'),
                    ),
                  ),
                // Compact bottom controls bar
                SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Mark as Solved — full-width row, only when flipped ──
                        if (_isFlipped && _currentFlashcard != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _markCardAsSolved,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  side: BorderSide(
                                    color: AppColors.success.withOpacity(0.6),
                                  ),
                                  backgroundColor:
                                      AppColors.success.withOpacity(0.06),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 18),
                                label: const Text(
                                  'Mark as Solved',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // ── Navigation row ───────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 28),
                              onPressed: _currentCardIndex > 0
                                  ? _handlePreviousCard
                                  : null,
                              color: _currentCardIndex > 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withOpacity(0.3),
                            ),
                            // Center actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Shuffle
                                IconButton(
                                  icon: const Icon(Icons.shuffle, size: 22),
                                  onPressed: _flashcards.isEmpty
                                      ? null
                                      : _handleRandomCard,
                                  color: AppColors.primary,
                                  tooltip: 'Random Card',
                                ),
                                // List all problems
                                IconButton(
                                  icon: const Icon(Icons.list_alt, size: 22),
                                  onPressed: _flashcards.isEmpty
                                      ? null
                                      : _showAllProblems,
                                  color: AppColors.primary,
                                  tooltip: 'List all problems',
                                ),
                                // Timer
                                IconButton(
                                  icon: Icon(
                                    _isTimerActive
                                        ? Icons.timer_off
                                        : Icons.timer,
                                    size: 22,
                                  ),
                                  onPressed: _toggleTimer,
                                  color: AppColors.primary,
                                  tooltip: 'Timer',
                                ),
                                if (_isTimerActive)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Text(
                                      _formatTime(_elapsedSeconds),
                                      style: AppTextStyles.body2.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                // Stats
                                IconButton(
                                  icon: const Icon(Icons.bar_chart, size: 22),
                                  onPressed: _showStatistics,
                                  color: AppColors.primary,
                                  tooltip: 'Statistics',
                                ),
                              ],
                            ),
                            // Next
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 28),
                              onPressed:
                                  _currentCardIndex < _flashcards.length - 1
                                      ? _handleNextCard
                                      : null,
                              color: _currentCardIndex < _flashcards.length - 1
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ],
                        ),
                        if (_flashcards.isNotEmpty)
                          Text(
                            '${_currentCardIndex + 1} of ${_flashcards.length}',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ], // Column.children
            ), // Column (Positioned.fill child)
          ), // Positioned.fill
          // Floating draggable AI chat button
          Positioned.fill(
            child: AiChatButton(currentCard: _currentFlashcard),
          ),
        ], // Stack.children
      ), // Stack
    );
  }
}
