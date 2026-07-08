import '../models/generated_problem.dart';
import 'llm_service.dart';

/// Interview style profiles for each major tech company.
/// Topics are drawn from publicly documented hiring patterns.
const Map<String, Map<String, dynamic>> companyProfiles = {
  'Google': {
    'emoji': '🔍',
    'topics': ['Graphs', 'Binary Search', 'Dynamic Programming', 'Arrays', 'Strings'],
    'note': 'Google values elegant, optimal solutions with rigorous complexity analysis.',
  },
  'Amazon': {
    'emoji': '📦',
    'topics': ['Trees', 'Arrays', 'Sliding Window', 'Dynamic Programming', 'Linked List'],
    'note': 'Amazon emphasises practical problem-solving under real-world constraints.',
  },
  'Meta': {
    'emoji': '🌐',
    'topics': ['Dynamic Programming', 'Graphs', 'Arrays', 'Strings', 'Two Pointers'],
    'note': 'Meta focuses on product-scale coding and efficient graph traversal.',
  },
  'Microsoft': {
    'emoji': '🪟',
    'topics': ['Trees', 'Linked List', 'Binary Search', 'Arrays', 'Stack'],
    'note': 'Microsoft values clean, readable code and solid data-structure knowledge.',
  },
  'Apple': {
    'emoji': '🍎',
    'topics': ['Arrays', 'Binary Search', 'Sliding Window', 'Two Pointers', 'Heap'],
    'note': 'Apple emphasises memory efficiency and hardware-aware optimisation.',
  },
  'Netflix': {
    'emoji': '🎬',
    'topics': ['Arrays', 'Heap', 'Sliding Window', 'Dynamic Programming', 'Graphs'],
    'note': 'Netflix focuses on data-processing and recommendation-style algorithms.',
  },
  'Uber': {
    'emoji': '🚗',
    'topics': ['Graphs', 'Arrays', 'Two Pointers', 'Backtracking', 'Binary Search'],
    'note': 'Uber emphasises routing, geospatial, and optimisation problems.',
  },
  'Airbnb': {
    'emoji': '🏠',
    'topics': ['Arrays', 'Strings', 'Dynamic Programming', 'Graphs', 'Backtracking'],
    'note': 'Airbnb focuses on search, matching, and scheduling algorithms.',
  },
};

/// Generates LeetCode-style problems using an [LlmService].
class ProblemGenerator {
  final LlmService _llmService;

  ProblemGenerator(this._llmService);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Builds a company-specific prompt selecting a relevant topic from that
  /// company's known interview profile.
  static String buildCompanyPrompt(String company, String difficulty) {
    final profile = companyProfiles[company];
    final topics = profile != null
        ? (profile['topics'] as List<String>)
        : ['Arrays', 'Dynamic Programming', 'Graphs'];
    final note = profile?['note'] as String? ?? '';

    // Pick topic based on difficulty index so each difficulty uses a different topic
    final diffIndex = ['Easy', 'Medium', 'Hard'].indexOf(difficulty);
    final topic = topics[diffIndex.clamp(0, topics.length - 1)];

    return '''You are an expert coding interview designer for $company. Generate an original $difficulty $topic coding problem in the style of $company engineering interviews.

$note

Format:

## Title
[problem title]

## Description
[clear problem description]

## Examples
[2-3 concrete input/output examples]

## Constraints
[constraints, one per line]

## Solution Approach
[optimal algorithm and key insight]

## Code
[complete working Python solution]

## Time Complexity
[Big-O time with justification]

## Space Complexity
[Big-O space with justification]

## Brute Force Approach
[naive O(n²) or exponential approach — no optimization]

## Brute Force Code
[complete working Python brute force solution]

Requirements:
- Must be an original problem, not a reproduction of any published problem.
- Should reflect $company interview style: $note
- Provide clean Python with meaningful variable names.''';
  }

  /// Builds a prompt for generating a problem similar in style and concept
  /// to [problemName], but entirely original — not a reproduction.
  static String buildPromptForSimilarProblem(
    String problemName,
    String category,
    String difficulty,
  ) {
    return '''You are an expert LeetCode problem designer. Generate a NEW $difficulty $category coding problem that is SIMILAR IN STYLE AND CONCEPT to "$problemName" but is an entirely original problem — not a reproduction of it.

The new problem should:
- Test the same core algorithmic technique as "$problemName"
- Be at $difficulty level
- Have a different theme, setting, or input data (not just a renamed version)

Format your response exactly as follows:

## Title
[problem title]

## Description
[clear problem description with context]

## Examples
[2-3 concrete input/output examples]

## Constraints
[list of constraints, one per line]

## Solution Approach
[explain the optimal algorithm and key insight]

## Code
[complete working Python solution]

## Time Complexity
[Big-O time complexity with brief justification]

## Space Complexity
[Big-O space complexity with brief justification]

## Brute Force Approach
[simple naive approach and why it is less efficient]

## Brute Force Code
[complete working Python brute force solution]

Requirements:
- Must be INSPIRED BY but NOT reproduce "$problemName".
- The core technique must match the $category pattern.
- Provide a clean, complete Python solution with meaningful variable names.''';
  }

  /// Generates a company-style problem and returns a parsed [GeneratedProblem].
  Future<GeneratedProblem> generateCompanyProblem({
    required String company,
    required String difficulty,
  }) async {
    final profile = companyProfiles[company];
    final topics = profile != null
        ? (profile['topics'] as List<String>)
        : ['Arrays'];
    final diffIndex = ['Easy', 'Medium', 'Hard'].indexOf(difficulty);
    final category = topics[diffIndex.clamp(0, topics.length - 1)];

    final prompt = buildCompanyPrompt(company, difficulty);
    final response = await _llmService.generate(prompt);
    final problem = _parseResponse(response, category, difficulty);

    // Return with company metadata embedded (preserve brute-force fields)
    return GeneratedProblem(
      title: problem.title,
      description: problem.description,
      examples: problem.examples,
      constraints: problem.constraints,
      solutionApproach: problem.solutionApproach,
      code: problem.code,
      bruteForceApproach: problem.bruteForceApproach,
      bruteForceCode: problem.bruteForceCode,
      timeComplexity: problem.timeComplexity,
      spaceComplexity: problem.spaceComplexity,
      category: category,
      difficulty: difficulty,
      generatedAt: DateTime.now(),
      company: company,
    );
  }

  /// Streams a company-style problem generation.
  Stream<String> generateCompanyProblemStream({
    required String company,
    required String difficulty,
  }) {
    final prompt = buildCompanyPrompt(company, difficulty);
    return _llmService.generateStream(prompt);
  }

  /// Builds a structured prompt for the LLM.
  static String buildPrompt(String category, String difficulty) {
    return '''You are an expert LeetCode problem designer. Generate a $difficulty $category coding problem in the following format:

## Title
[problem title]

## Description
[clear problem description with context]

## Examples
[2-3 concrete input/output examples]

## Constraints
[list of constraints, one per line]

## Solution Approach
[explain the optimal algorithm and key insight]

## Code
[complete working Python solution]

## Time Complexity
[Big-O time complexity with brief justification]

## Space Complexity
[Big-O space complexity with brief justification]

## Brute Force Approach
[naive O(n²) or exponential approach — no optimization]

## Brute Force Code
[complete working Python brute force solution]

Requirements:
- The problem must be a genuine $difficulty $category LeetCode-style problem.
- Provide a clean, complete Python solution with meaningful variable names.
- Include at least 2 examples.
- List all important constraints.
- Keep the solution approach concise but insightful.''';
  }

  /// Generates a problem and streams tokens as they are produced.
  Stream<String> generateProblemStream({
    required String category,
    required String difficulty,
  }) {
    final prompt = buildPrompt(category, difficulty);
    return _llmService.generateStream(prompt);
  }

  /// Generates a problem and returns a parsed [GeneratedProblem].
  Future<GeneratedProblem> generateProblem({
    required String category,
    required String difficulty,
  }) async {
    final prompt = buildPrompt(category, difficulty);
    final response = await _llmService.generate(prompt);
    return _parseResponse(response, category, difficulty);
  }

  /// Streams a problem similar in concept to [problemName].
  Stream<String> generateSimilarProblemStream({
    required String problemName,
    required String category,
    required String difficulty,
  }) {
    final prompt = buildPromptForSimilarProblem(problemName, category, difficulty);
    return _llmService.generateStream(prompt);
  }

  /// Generates a problem similar in concept to [problemName] and parses it.
  Future<GeneratedProblem> generateSimilarProblem({
    required String problemName,
    required String category,
    required String difficulty,
  }) async {
    final prompt = buildPromptForSimilarProblem(problemName, category, difficulty);
    final response = await _llmService.generate(prompt);
    return _parseResponse(response, category, difficulty);
  }

  // ---------------------------------------------------------------------------
  // Response parsing
  // ---------------------------------------------------------------------------

  GeneratedProblem _parseResponse(
    String response,
    String category,
    String difficulty,
  ) {
    return GeneratedProblem(
      title: _extractSection(response, 'Title') ?? '$category Problem',
      description: _extractSection(response, 'Description') ?? response,
      examples: _extractListSection(response, 'Examples'),
      constraints: _extractListSection(response, 'Constraints'),
      solutionApproach:
          _extractSection(response, 'Solution Approach') ?? 'See code below.',
      code: _extractCode(response),
      bruteForceApproach:
          _extractSection(response, 'Brute Force Approach') ?? '',
      bruteForceCode: _extractCodeFromSection(response, 'Brute Force Code'),
      timeComplexity: _extractSection(response, 'Time Complexity') ?? 'O(n)',
      spaceComplexity: _extractSection(response, 'Space Complexity') ?? 'O(1)',
      category: category,
      difficulty: difficulty,
      generatedAt: DateTime.now(),
    );
  }

  /// Extracts the content of a `## Heading` section (single-line or paragraph).
  String? _extractSection(String text, String heading) {
    // Match the heading and capture text until the next ## heading or end.
    final pattern = RegExp(
      r'##\s*' + RegExp.escape(heading) + r'\s*\n([\s\S]*?)(?=\n##\s|\z)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match == null) return null;
    final content = match.group(1)?.trim() ?? '';
    return content.isEmpty ? null : content;
  }

  /// Extracts a section whose content is a list, returning each non-empty line.
  List<String> _extractListSection(String text, String heading) {
    final raw = _extractSection(text, heading);
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Extracts code from the first fenced code block in the response.
  /// Used for the optimized solution (always appears before brute force).
  String _extractCode(String text) {
    final codeBlockPattern = RegExp(
      r'```(?:python|py)?\s*\n([\s\S]*?)```',
      caseSensitive: false,
    );
    final match = codeBlockPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    // Fallback: look for a ## Code section without fences.
    return _extractSection(text, 'Code') ?? '';
  }

  /// Extracts the first fenced code block found within a specific [sectionHeading].
  /// Used to parse the brute-force code block separately from the optimized one.
  String _extractCodeFromSection(String text, String sectionHeading) {
    final section = _extractSection(text, sectionHeading);
    if (section == null || section.isEmpty) return '';
    final codeBlockPattern = RegExp(
      r'```(?:python|py)?\s*\n([\s\S]*?)```',
      caseSensitive: false,
    );
    final match = codeBlockPattern.firstMatch(section);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    // Fallback: return the raw section content (may already be plain code).
    return section.trim();
  }
}
