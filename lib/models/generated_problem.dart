class GeneratedProblem {
  final String title;
  final String description;
  final List<String> examples;
  final List<String> constraints;
  final String solutionApproach;
  final String code;
  final String bruteForceApproach;
  final String bruteForceCode;
  final String timeComplexity;
  final String spaceComplexity;
  final String category;
  final String difficulty;
  final DateTime generatedAt;
  final String? company; // optional — set for company-style problems

  const GeneratedProblem({
    required this.title,
    required this.description,
    required this.examples,
    required this.constraints,
    required this.solutionApproach,
    required this.code,
    this.bruteForceApproach = '',
    this.bruteForceCode = '',
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.category,
    required this.difficulty,
    required this.generatedAt,
    this.company,
  });

  /// Produces a markdown string that matches the existing flashcard format
  /// (## Question ... ## Solution ...) so it can be stored as a Flashcard.
  /// Optimized solution is shown first; brute force follows if available.
  String toMarkdownContent() {
    final buffer = StringBuffer();

    buffer.writeln('## Question');
    buffer.writeln();
    buffer.writeln('**Category:** $category | **Difficulty:** $difficulty');
    buffer.writeln();
    buffer.writeln(description);
    buffer.writeln();

    if (examples.isNotEmpty) {
      buffer.writeln('### Examples');
      buffer.writeln();
      for (final example in examples) {
        buffer.writeln('```');
        buffer.writeln(example);
        buffer.writeln('```');
        buffer.writeln();
      }
    }

    if (constraints.isNotEmpty) {
      buffer.writeln('### Constraints');
      buffer.writeln();
      for (final constraint in constraints) {
        buffer.writeln('- $constraint');
      }
      buffer.writeln();
    }

    buffer.writeln('## Solution');
    buffer.writeln();

    // ── Optimized solution first ─────────────────────────────────────────────
    buffer.writeln('### ⚡ Optimized Approach');
    buffer.writeln();
    buffer.writeln(solutionApproach);
    buffer.writeln();
    buffer.writeln('### Optimized Code');
    buffer.writeln();
    buffer.writeln('```python');
    buffer.writeln(code);
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('### Complexity');
    buffer.writeln();
    buffer.writeln('- **Time:** $timeComplexity');
    buffer.writeln('- **Space:** $spaceComplexity');

    // ── Brute force (only if present) ───────────────────────────────────────
    if (bruteForceCode.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('### 🐌 Brute Force Approach');
      buffer.writeln();
      buffer.writeln(bruteForceApproach.isNotEmpty
          ? bruteForceApproach
          : 'Naive approach using nested iteration.');
      buffer.writeln();
      buffer.writeln('### Brute Force Code');
      buffer.writeln();
      buffer.writeln('```python');
      buffer.writeln(bruteForceCode);
      buffer.writeln('```');
    }

    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'examples': examples.join('|||'),
      'constraints': constraints.join('|||'),
      'solution_approach': solutionApproach,
      'code': code,
      'brute_force_approach': bruteForceApproach,
      'brute_force_code': bruteForceCode,
      'time_complexity': timeComplexity,
      'space_complexity': spaceComplexity,
      'category': category,
      'difficulty': difficulty,
      'generated_at': generatedAt.toIso8601String(),
      'company': company,
    };
  }

  factory GeneratedProblem.fromMap(Map<String, dynamic> map) {
    List<String> splitField(dynamic value) {
      if (value == null || (value as String).isEmpty) return [];
      return value.split('|||');
    }

    return GeneratedProblem(
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      examples: splitField(map['examples']),
      constraints: splitField(map['constraints']),
      solutionApproach: map['solution_approach'] as String? ?? '',
      code: map['code'] as String? ?? '',
      bruteForceApproach: map['brute_force_approach'] as String? ?? '',
      bruteForceCode: map['brute_force_code'] as String? ?? '',
      timeComplexity: map['time_complexity'] as String? ?? '',
      spaceComplexity: map['space_complexity'] as String? ?? '',
      category: map['category'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? '',
      generatedAt: map['generated_at'] != null
          ? DateTime.parse(map['generated_at'] as String)
          : DateTime.now(),
      company: map['company'] as String?,
    );
  }

  GeneratedProblem copyWith({
    String? title,
    String? description,
    List<String>? examples,
    List<String>? constraints,
    String? solutionApproach,
    String? code,
    String? bruteForceApproach,
    String? bruteForceCode,
    String? timeComplexity,
    String? spaceComplexity,
    String? category,
    String? difficulty,
    DateTime? generatedAt,
    String? company,
  }) {
    return GeneratedProblem(
      title: title ?? this.title,
      description: description ?? this.description,
      examples: examples ?? this.examples,
      constraints: constraints ?? this.constraints,
      solutionApproach: solutionApproach ?? this.solutionApproach,
      code: code ?? this.code,
      bruteForceApproach: bruteForceApproach ?? this.bruteForceApproach,
      bruteForceCode: bruteForceCode ?? this.bruteForceCode,
      timeComplexity: timeComplexity ?? this.timeComplexity,
      spaceComplexity: spaceComplexity ?? this.spaceComplexity,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      generatedAt: generatedAt ?? this.generatedAt,
      company: company ?? this.company,
    );
  }
}
