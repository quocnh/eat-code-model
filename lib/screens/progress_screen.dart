import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';

class ProgressScreen extends StatefulWidget {
  // const ProgressScreen({super.key});
  const ProgressScreen({Key? key}) : super(key: key);
  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

// Make the state class public so it can be accessed from other screens
class ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic> _progressStats = {};
  List<Map<String, dynamic>> _categoryStats = [];
  Map<String, List<Flashcard>> _solvedCards = {};
  List<Flashcard> _bookmarkedCards = [];
  bool _isLoading = true;
  String? _selectedCategory;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProgressStats();
    _loadBookmarkedCards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Add this method to allow external refresh
  void refreshProgress() {
    _loadProgressStats();
    _loadBookmarkedCards();
  }

  Future<void> _loadProgressStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _dbHelper.getProgressStats();
      final catStats = await _dbHelper.getCategoryStats();

      if (_selectedCategory != null) {
        final solvedCards =
            await _dbHelper.getSolvedCardsByCategory(_selectedCategory!);
        setState(() {
          _solvedCards = {_selectedCategory!: solvedCards};
        });
      }

      setState(() {
        _progressStats = stats;
        _categoryStats = catStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading progress stats: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading progress stats: $e')),
        );
      }
    }
  }

  Future<void> _loadBookmarkedCards() async {
    if (!mounted) return;
    final cards = await _dbHelper.getFlashcards(isBookmarked: true);
    if (!mounted) return;
    setState(() => _bookmarkedCards = cards);
  }

  Future<void> _removeBookmark(int cardId) async {
    await _dbHelper.toggleBookmark(cardId);
    await _loadBookmarkedCards();
  }

  Future<void> _loadSolvedCardsForCategory(String category) async {
    setState(() => _isLoading = true);

    try {
      final cards = await _dbHelper.getSolvedCardsByCategory(category);
      setState(() {
        _selectedCategory = category;
        _solvedCards = {category: cards};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading solved cards: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showCardDetails(Flashcard card) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Solved',
                            style: AppTextStyles.chipText.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: AppTextStyles.heading1,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Question:',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: card.question,
                        selectable: true,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Solution:',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: card.solution,
                        selectable: true,
                      ),
                      if (card.solvedAt != null) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Solved on: ${_formatDate(card.solvedAt!)}',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final totalCards = category['total_cards'] ?? 0;
    final completedCards = category['completed_cards'] ?? 0;
    final progress = totalCards == 0 ? 0.0 : completedCards / totalCards;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _loadSolvedCardsForCategory(category['category']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category['category'],
                    style: AppTextStyles.heading2,
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.textSecondary.withOpacity(0.1),
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                '$completedCards/$totalCards cards completed',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolvedCardsList(String category) {
    final cards = _solvedCards[category] ?? [];

    if (cards.isEmpty) {
      return Center(
        child: Text(
          'No solved cards in this category yet',
          style: AppTextStyles.body2,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: ListTile(
            title: Text(
              card.title,
              style: AppTextStyles.body1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Difficulty: ${card.difficulty}',
                  style: AppTextStyles.body2,
                ),
                if (card.solvedAt != null)
                  Text(
                    'Solved: ${_formatDate(card.solvedAt!)}',
                    style: AppTextStyles.body2,
                  ),
              ],
            ),
            trailing: Icon(
              Icons.check_circle,
              color: AppColors.success,
            ),
            onTap: () => _showCardDetails(card),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progress'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadProgressStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Progress',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Cards',
                                _progressStats['total_cards']?.toString() ??
                                    '0',
                              ),
                              _buildStatItem(
                                'Solved',
                                _progressStats['completed_cards']?.toString() ??
                                    '0',
                              ),
                              _buildStatItem(
                                'Reviews',
                                _progressStats['total_reviews']?.toString() ??
                                    '0',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _progressStats['total_cards'] == null ||
                                    _progressStats['total_cards'] == 0
                                ? 0
                                : (_progressStats['completed_cards'] ?? 0) /
                                    _progressStats['total_cards'],
                            backgroundColor:
                                AppColors.textSecondary.withOpacity(0.1),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedCategory == null) ...[
                    Text('Progress by Category', style: AppTextStyles.heading2),
                    const SizedBox(height: 16),
                    ...List.generate(
                      _categoryStats.length,
                      (index) => _buildCategoryCard(_categoryStats[index]),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => setState(() {
                            _selectedCategory = null;
                            _solvedCards.clear();
                          }),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solved $_selectedCategory Cards',
                              style: AppTextStyles.heading2,
                            ),
                            Text(
                              'Tap a card to view details',
                              style: AppTextStyles.body2
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSolvedCardsList(_selectedCategory!),
                  ],
                ],
              ),
            ),
          );
  }

  Widget _buildSavedTab() {
    return RefreshIndicator(
      onRefresh: _loadBookmarkedCards,
      child: _bookmarkedCards.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.bookmark_outline,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('No saved cards yet',
                          style: AppTextStyles.body1
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Bookmark cards to review them later',
                          style: AppTextStyles.body2),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookmarkedCards.length,
              itemBuilder: (context, index) {
                final card = _bookmarkedCards[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showCardDetails(card),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(card.title, style: AppTextStyles.body1),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _difficultyColor(card.difficulty)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        card.difficulty,
                                        style: TextStyle(
                                          color:
                                              _difficultyColor(card.difficulty),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(card.category,
                                        style: AppTextStyles.body2),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark,
                                color: AppColors.warning),
                            onPressed: card.id != null
                                ? () => _removeBookmark(card.id!)
                                : null,
                            tooltip: 'Remove bookmark',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.easy;
      case 'hard':
        return AppColors.hard;
      default:
        return AppColors.medium;
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
