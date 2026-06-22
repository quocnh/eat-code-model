import '../database/database_helper.dart';
import '../models/flashcard.dart';
import '../models/progress.dart';
import 'llm_service.dart';
import 'problem_generator.dart';

/// Generates and seeds the initial problem library on first app launch.
///
/// Uses [TemplateLlmService] so it always works — even before CodeGemma
/// is downloaded. Produces:
///   • 36 general problems  (12 categories × 3 difficulties)
///   • 24 company problems  (8 companies × 3 difficulties)
///
/// All problems are 100% original — no real LeetCode content.
class FirstLaunchService {
  static const _categories = [
    'Arrays', 'Strings', 'Trees', 'Graphs', 'Dynamic Programming',
    'Binary Search', 'Two Pointers', 'Sliding Window',
    'Stack', 'Heap', 'Backtracking', 'Linked List',
  ];

  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  static const _companies = [
    'Google', 'Amazon', 'Meta', 'Microsoft',
    'Apple', 'Netflix', 'Uber', 'Airbnb',
  ];

  /// Generates all problems and inserts them into [db].
  /// Returns the total number of problems created.
  static Future<int> generateAndSeed(DatabaseHelper db) async {
    final service = TemplateLlmService();
    await service.initialize();
    final generator = ProblemGenerator(service);

    int count = 0;

    // ── 1. General problems (36 total) ───────────────────────────────────────
    for (final category in _categories) {
      for (final difficulty in _difficulties) {
        try {
          final problem = await generator.generateProblem(
            category: category,
            difficulty: difficulty,
          );
          count += await _saveFlashcard(db, problem);
        } catch (_) {
          // Never block startup on a single failure
        }
      }
    }

    // ── 2. Company-style problems (24 total) ─────────────────────────────────
    for (final company in _companies) {
      for (final difficulty in _difficulties) {
        try {
          final problem = await generator.generateCompanyProblem(
            company: company,
            difficulty: difficulty,
          );
          count += await _saveFlashcard(db, problem);
        } catch (_) {
          // Never block startup on a single failure
        }
      }
    }

    return count;
  }

  static Future<int> _saveFlashcard(
      DatabaseHelper db, dynamic problem) async {
    final flashcard = Flashcard(
      title: problem.title as String,
      content: (problem.toMarkdownContent()) as String,
      difficulty: problem.difficulty as String,
      category: problem.category as String,
      company: problem.company as String?,
      isPremium: false,
      createdAt: DateTime.now(),
    );

    final id = await db.insertFlashcard(flashcard);
    await db.updateProgress(Progress(
      flashcardId: id,
      isCompleted: false,
      confidenceLevel: 0,
      timesReviewed: 0,
    ));
    return 1;
  }
}
