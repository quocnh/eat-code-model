import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/flashcard.dart';
import '../models/progress.dart';
import '../services/first_launch_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'leetcode_flashcards.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  /// Clears seed data when upgrading to a schema version that changes the
  /// generated content format.
  /// v2 added brute-force sections; v3 fixes company cards missing brute-force.
  /// insertSampleData() will re-seed on the next call.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Wipe seeded cards so insertSampleData re-generates with correct brute-force.
      await db.rawDelete('DELETE FROM user_progress');
      await db.rawDelete('DELETE FROM flashcards');
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flashcards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        markdown_content TEXT NOT NULL,
        question TEXT NOT NULL,
        solution TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        category TEXT NOT NULL,
        company TEXT,
        is_premium INTEGER NOT NULL DEFAULT 0,
        is_bookmarked INTEGER NOT NULL DEFAULT 0,
        is_solved INTEGER NOT NULL DEFAULT 0,
        solved_at TEXT,
        created_at TEXT NOT NULL,
        last_viewed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flashcard_id INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        confidence_level INTEGER DEFAULT 0,
        times_reviewed INTEGER DEFAULT 0,
        last_reviewed_at TEXT,
        solved_at TEXT,
        FOREIGN KEY(flashcard_id) REFERENCES flashcards(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_flashcards_category ON flashcards(category)');
    await db.execute(
        'CREATE INDEX idx_flashcards_difficulty ON flashcards(difficulty)');
    await db.execute(
        'CREATE INDEX idx_progress_flashcard ON user_progress(flashcard_id)');
  }

  Future<int> insertFlashcard(Flashcard flashcard) async {
    Database db = await database;
    return await db.insert('flashcards', flashcard.toMap());
  }

  Future<List<Flashcard>> getFlashcards({
    String? difficulty,
    String? category,
    bool? isPremium,
    bool? isBookmarked,
    bool excludeCompleted = false,
  }) async {
    Database db = await database;

    List<String> conditions = [];
    List<dynamic> arguments = [];

    if (difficulty != null) {
      conditions.add('f.difficulty = ?');
      arguments.add(difficulty);
    }

    if (category != null) {
      conditions.add('f.category = ?');
      arguments.add(category);
    }

    if (isPremium != null) {
      conditions.add('f.is_premium = ?');
      arguments.add(isPremium ? 1 : 0);
    }

    if (isBookmarked != null) {
      conditions.add('f.is_bookmarked = ?');
      arguments.add(isBookmarked ? 1 : 0);
    }

    // Add condition to exclude completed cards
    if (excludeCompleted) {
      conditions.add('''
        NOT EXISTS (
          SELECT 1 FROM user_progress p 
          WHERE p.flashcard_id = f.id 
          AND p.is_completed = 1
        )
      ''');
    }

    String whereClause =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT f.*
      FROM flashcards f
      LEFT JOIN user_progress p ON f.id = p.flashcard_id
      $whereClause
      ORDER BY f.last_viewed_at DESC
    ''', arguments);

    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<List<Flashcard>> getSolvedCardsByCategory(String category) async {
    Database db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT f.*
      FROM flashcards f
      INNER JOIN user_progress p ON f.id = p.flashcard_id
      WHERE f.category = ? AND p.is_completed = 1
      ORDER BY p.last_reviewed_at DESC
    ''', [category]);

    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<void> toggleBookmark(int id) async {
    Database db = await database;
    await db.rawUpdate('''
      UPDATE flashcards 
      SET is_bookmarked = CASE WHEN is_bookmarked = 1 THEN 0 ELSE 1 END 
      WHERE id = ?
    ''', [id]);
  }

  Future<void> updateLastViewed(int id) async {
    Database db = await database;
    await db.update(
      'flashcards',
      {'last_viewed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateProgress(Progress progress) async {
    Database db = await database;

    // First, insert or update progress
    await db.insert(
      'user_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Then, if the card is completed, update the flashcard's solved status
    if (progress.isCompleted) {
      await updateCardSolvedStatus(progress.flashcardId, true);
    }
  }

  Future<Progress?> getProgress(int flashcardId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_progress',
      where: 'flashcard_id = ?',
      whereArgs: [flashcardId],
    );

    if (maps.isEmpty) return null;
    return Progress.fromMap(maps.first);
  }

  Future<Map<String, dynamic>> getProgressStats() async {
    Database db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT f.id) as total_cards,
        SUM(CASE WHEN p.is_completed = 1 THEN 1 ELSE 0 END) as completed_cards,
        ROUND(AVG(p.confidence_level), 2) as avg_confidence,
        SUM(p.times_reviewed) as total_reviews
      FROM flashcards f
      LEFT JOIN user_progress p ON f.id = p.flashcard_id
    ''');

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getCategoryStats() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        f.category,
        COUNT(DISTINCT f.id) as total_cards,
        SUM(CASE WHEN p.is_completed = 1 THEN 1 ELSE 0 END) as completed_cards
      FROM flashcards f
      LEFT JOIN user_progress p ON f.id = p.flashcard_id
      GROUP BY f.category
      ORDER BY f.category
    ''');
  }

  Future<void> updateCardSolvedStatus(int cardId, bool isSolved) async {
    Database db = await database;
    await db.rawUpdate('''
      UPDATE flashcards 
      SET is_solved = ?, 
          solved_at = ?
      WHERE id = ?
    ''', [
      isSolved ? 1 : 0,
      isSolved ? DateTime.now().toIso8601String() : null,
      cardId
    ]);
  }

  Future<void> resetProgress() async {
    Database db = await database;
    await db.transaction((txn) async {
      await txn.delete('user_progress');
      await txn.update('flashcards', {'is_solved': 0, 'solved_at': null});
    });
  }

  Future<void> clearBookmarks() async {
    Database db = await database;
    await db.update('flashcards', {'is_bookmarked': 0});
  }

  Future<void> insertSampleData() async {
    Database db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM flashcards'));

    // Only seed on a truly empty database
    if (count != null && count > 0) return;

    // Generate 36 original AI problems (12 categories × 3 difficulties)
    // using the built-in template generator — no internet or model download required.
    await FirstLaunchService.generateAndSeed(this);
  }

  Future<List<String>> getCompanies() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT company 
      FROM flashcards 
      WHERE company IS NOT NULL
      ORDER BY company
    ''');

    return result.map((row) => row['company'] as String).toList();
  }

  Future<List<Flashcard>> getFlashcardsByCompany(String company) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'flashcards',
      where: 'company = ?',
      whereArgs: [company],
    );

    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<Map<String, int>> getDifficultyCountByCompany(String company) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT difficulty, COUNT(*) as count
      FROM flashcards
      WHERE company = ?
      GROUP BY difficulty
    ''', [company]);

    Map<String, int> counts = {
      'Easy': 0,
      'Medium': 0,
      'Hard': 0,
    };

    for (var row in result) {
      counts[row['difficulty'] as String] = row['count'] as int;
    }

    return counts;
  }
}
