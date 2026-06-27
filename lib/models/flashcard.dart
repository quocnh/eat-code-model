class Flashcard {
  final int? id;
  final String title;
  final String markdownContent;
  final String question;
  final String solution;
  final String difficulty;
  final String category;
  final String? company;
  final bool isPremium;
  final bool isBookmarked;
  final bool isSolved;
  final DateTime createdAt;
  final DateTime? lastViewedAt;
  final DateTime? solvedAt;
  
  late final List<String> _contentParts;
  late final String _questionContent;
  late final String _solutionContent;

  Flashcard({
    this.id,
    required this.title,
    required String content,
    String? question,
    String? solution,
    required this.difficulty,
    required this.category,
    this.company,
    this.isPremium = false,
    this.isBookmarked = false,
    this.isSolved = false,
    this.solvedAt,
    DateTime? createdAt,
    this.lastViewedAt,
  }) :
    markdownContent = content,
    question = question ?? _extractQuestion(content),
    solution = solution ?? _extractSolution(content),
    createdAt = createdAt ?? DateTime.now() {
      _contentParts = _splitContent(markdownContent);
      _questionContent = _contentParts.isNotEmpty ? _contentParts[0].trim() : '';
      _solutionContent = _contentParts.length > 1 ? _contentParts[1].trim() : '';
    }

  static String _extractQuestion(String markdown) {
    if (markdown.isEmpty) return ''; // Handle empty content
    final questionMatch = RegExp(r'## Question\s+(.*?)(?=## Solution|\z)', 
      dotAll: true).firstMatch(markdown);
    return questionMatch?.group(1)?.trim() ?? '';
  }

  static String _extractSolution(String markdown) {
    if (markdown.isEmpty) return ''; // Handle empty content
    final solutionMatch = RegExp(r'## Solution\s+(.*)', 
      dotAll: true).firstMatch(markdown);
    return solutionMatch?.group(1)?.trim() ?? '';
  }

  List<String> _splitContent(String content) {
    if (content.isEmpty) return []; // Handle empty content
    return content.split('## Solution');
  }

  String getQuestionContent() => _questionContent;
  String getSolutionContent() => _solutionContent;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'markdown_content': markdownContent,
      'question': question,
      'solution': solution,
      'difficulty': difficulty,
      'category': category,
      'company': company,
      'is_premium': isPremium ? 1 : 0,
      'is_bookmarked': isBookmarked ? 1 : 0,
      'is_solved': isSolved ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_viewed_at': lastViewedAt?.toIso8601String(),
      'solved_at': solvedAt?.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      content: map['markdown_content'] ?? '', // Ensure content is not null
      question: map['question'] ?? '',
      solution: map['solution'] ?? '',
      difficulty: map['difficulty'] ?? '',
      category: map['category'] ?? '',
      company: map['company'],
      isPremium: map['is_premium'] == 1,
      isBookmarked: map['is_bookmarked'] == 1,
      isSolved: map['is_solved'] == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      lastViewedAt: map['last_viewed_at'] != null 
        ? DateTime.parse(map['last_viewed_at'] as String)
        : null,
      solvedAt: map['solved_at'] != null 
        ? DateTime.parse(map['solved_at'] as String)
        : null,
    );
  }

  Flashcard copyWith({
    int? id,
    String? title,
    String? content,
    String? question,
    String? solution,
    String? difficulty,
    String? category,
    String? company,
    bool? isPremium,
    bool? isBookmarked,
    bool? isSolved,
    DateTime? createdAt,
    DateTime? lastViewedAt,
    DateTime? solvedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.markdownContent,
      question: question ?? this.question,
      solution: solution ?? this.solution,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      company: company ?? this.company,
      isPremium: isPremium ?? this.isPremium,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isSolved: isSolved ?? this.isSolved,
      createdAt: createdAt ?? this.createdAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      solvedAt: solvedAt ?? this.solvedAt,
    );
  }
}