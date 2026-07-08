import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic> _progressStats = {};
  Map<String, Map<String, dynamic>> _categoryStatsMap = {};
  Map<String, List<Flashcard>> _solvedCards = {};
  List<Flashcard> _bookmarkedCards = [];
  bool _isLoading = true;
  String? _selectedCategory;
  late TabController _tabController;

  // Fixed ordered category list — matches Cards & Training exactly
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Arrays',              'emoji': '📋', 'color': Color(0xFF1565C0)},
    {'name': 'Strings',             'emoji': '🔤', 'color': Color(0xFF00897B)},
    {'name': 'Trees',               'emoji': '🌳', 'color': Color(0xFF2E7D32)},
    {'name': 'Graphs',              'emoji': '🕸️', 'color': Color(0xFF4527A0)},
    {'name': 'Dynamic Programming', 'emoji': '📊', 'color': Color(0xFF6A1B9A)},
    {'name': 'Binary Search',       'emoji': '🔍', 'color': Color(0xFF1976D2)},
    {'name': 'Two Pointers',        'emoji': '👆', 'color': Color(0xFF0277BD)},
    {'name': 'Sliding Window',      'emoji': '🪟', 'color': Color(0xFF006064)},
    {'name': 'Stack',               'emoji': '📚', 'color': Color(0xFF558B2F)},
    {'name': 'Heap',                'emoji': '⛰️', 'color': Color(0xFFBF360C)},
    {'name': 'Backtracking',        'emoji': '🔀', 'color': Color(0xFFAD1457)},
    {'name': 'Linked List',         'emoji': '🔗', 'color': Color(0xFFE65100)},
  ];

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

  void refreshProgress() {
    _loadProgressStats();
    _loadBookmarkedCards();
  }

  Future<void> _loadProgressStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _dbHelper.getProgressStats();
      final catStats = await _dbHelper.getCategoryStats();

      final map = <String, Map<String, dynamic>>{};
      for (final cat in catStats) {
        map[cat['category'] as String] = cat;
      }

      setState(() {
        _progressStats = stats;
        _categoryStatsMap = map;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading progress stats: $e');
      setState(() => _isLoading = false);
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

  // ── Scaffold ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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

  // ── Progress tab ────────────────────────────────────────────────────────────

  Widget _buildProgressTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedCategory != null) {
      return _buildSolvedCategoryView();
    }

    return RefreshIndicator(
      onRefresh: _loadProgressStats,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildOverallCard(),
          _buildCategorySection(),
        ],
      ),
    );
  }

  // Overall gradient stats card
  Widget _buildOverallCard() {
    final total = _progressStats['total_cards'] ?? 0;
    final solved = _progressStats['completed_cards'] ?? 0;
    final reviews = _progressStats['total_reviews'] ?? 0;
    final progress = total == 0 ? 0.0 : (solved as num) / (total as num);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge('Total', total.toString()),
              _buildStatBadge('Solved', solved.toString()),
              _buildStatBadge('Reviews', reviews.toString()),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toInt()}% Complete',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // 12-category section
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'By Category',
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
          ),
        ),
        ..._categories.map(_buildCategoryCard),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final name = cat['name'] as String;
    final emoji = cat['emoji'] as String;
    final color = cat['color'] as Color;

    final stats = _categoryStatsMap[name];
    final total = (stats?['total_cards'] ?? 0) as num;
    final solved = (stats?['completed_cards'] ?? 0) as num;
    final progress = total == 0 ? 0.0 : solved / total;

    return GestureDetector(
      onTap: () => _loadSolvedCardsForCategory(name),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Coloured header strip
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: color.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            // Progress body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total == 0
                        ? 'No cards yet'
                        : '${solved.toInt()} / ${total.toInt()} cards solved',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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

  // ── Solved cards detail view ────────────────────────────────────────────────

  Widget _buildSolvedCategoryView() {
    final cat = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () =>
          {'name': _selectedCategory!, 'emoji': '📝', 'color': AppColors.primary},
    );
    final color = cat['color'] as Color;
    final emoji = cat['emoji'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        Container(
          color: color.withOpacity(0.08),
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedCategory = null;
                  _solvedCards.clear();
                }),
              ),
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCategory!,
                      style: AppTextStyles.heading2.copyWith(color: color),
                    ),
                    Text(
                      'Tap a card to view details',
                      style: AppTextStyles.body2
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildSolvedCardsList(_selectedCategory!)),
      ],
    );
  }

  Widget _buildSolvedCardsList(String category) {
    final cards = _solvedCards[category] ?? [];

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No solved cards yet',
              style: AppTextStyles.body1
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Go practice some $category problems!',
              style: AppTextStyles.body2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(card.title, style: AppTextStyles.body1),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _difficultyChip(card.difficulty),
                  if (card.solvedAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '✓ ${_formatDate(card.solvedAt!)}',
                      style:
                          AppTextStyles.body2.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            trailing:
                const Icon(Icons.check_circle, color: AppColors.success),
            onTap: () => _showCardDetails(card),
          ),
        );
      },
    );
  }

  Widget _difficultyChip(String difficulty) {
    final color = _difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Solved',
                            style: AppTextStyles.chipText
                                .copyWith(color: AppColors.success),
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
                      Text(card.title, style: AppTextStyles.heading1),
                      const SizedBox(height: 16),
                      Text(
                        'Question:',
                        style: AppTextStyles.heading2
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(data: card.question, selectable: true),
                      const SizedBox(height: 24),
                      Text(
                        'Solution:',
                        style: AppTextStyles.heading2
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(data: card.solution, selectable: true),
                      if (card.solvedAt != null) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'Solved on: ${_formatDate(card.solvedAt!)}',
                              style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textSecondary),
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

  // ── Saved tab ───────────────────────────────────────────────────────────────

  Widget _buildSavedTab() {
    return RefreshIndicator(
      onRefresh: _loadBookmarkedCards,
      child: _bookmarkedCards.isEmpty
          ? ListView(
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved cards yet',
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bookmark cards to review them later',
                        style: AppTextStyles.body2,
                      ),
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
                                    _difficultyChip(card.difficulty),
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

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

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
