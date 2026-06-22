import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => BookmarksScreenState();
}

class BookmarksScreenState extends State<BookmarksScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Flashcard> _bookmarkedCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedCards();
  }

  Future<void> refreshBookmarks() async {
    await _loadBookmarkedCards();
  }

  Future<void> _loadBookmarkedCards() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final cards = await _dbHelper.getFlashcards(isBookmarked: true);

    if (!mounted) return;

    setState(() {
      _bookmarkedCards = cards;
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(int cardId) async {
    await _dbHelper.toggleBookmark(cardId);
    await _loadBookmarkedCards();
  }

  void _showCardDetail(Flashcard card) {
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
                        color: _getDifficultyColor(card.difficulty)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        card.difficulty,
                        style: AppTextStyles.chipText.copyWith(
                          color: _getDifficultyColor(card.difficulty),
                        ),
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
                      if (card.company != null) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Company: ${card.company}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Cards'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookmarkedCards,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookmarkedCards.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_outline,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved cards yet',
                              style: AppTextStyles.body1.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
                          onTap: () => _showCardDetail(card),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _getDifficultyColor(card.difficulty)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        card.difficulty,
                                        style: AppTextStyles.chipText.copyWith(
                                          color: _getDifficultyColor(
                                              card.difficulty),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark),
                                      color: AppColors.primary,
                                      onPressed: () =>
                                          _removeBookmark(card.id!),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card.title,
                                  style: AppTextStyles.heading2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card.question,
                                  style: AppTextStyles.body2,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.folder_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      card.category,
                                      style: AppTextStyles.body2.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (card.company != null) ...[
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.business,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        card.company!,
                                        style: AppTextStyles.body2.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
