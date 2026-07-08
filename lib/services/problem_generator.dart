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

Company style: $note

## Title
[A concise, descriptive problem title]

## Description
[A clear problem statement of at least 80 words. Define the input, the task, and the expected output. Include context that reflects $company-scale engineering.]

## Examples
Example 1:
Input: [actual input value]
Output: [actual output value]
Explanation: [why this output is correct]

Example 2:
Input: [different input, ideally an edge case — empty, single element, duplicates, or negatives]
Output: [actual output value]
Explanation: [why this output is correct]

## Constraints
[Each constraint on its own line with numeric bounds, e.g.:
- 1 <= nums.length <= 10^5
- -10^4 <= nums[i] <= 10^4]

## Solution Approach
[Explain the optimal algorithm in 2-4 sentences: the core insight, data structure used, and complexity achieved.]

## Code
```python
def solution_function_name(param1, param2):
    """Complete, runnable Python optimal solution."""
    # full implementation — no placeholders
    pass
```

## Time Complexity
O(...) — [one-sentence justification]

## Space Complexity
O(...) — [one-sentence justification]

## Brute Force Approach
[Describe a DIFFERENT, simpler algorithm — must use a fundamentally different strategy from optimal.]

## Brute Force Code
```python
def solution_brute_force(param1, param2):
    """Complete, runnable Python brute force — DIFFERENT algorithm from optimal."""
    # full implementation — no placeholders
    pass
```

STRICT REQUIREMENTS:
1. Original problem — not a reproduction of any published problem.
2. Description MUST be ≥ 80 words.
3. MUST include 2 Examples each with Input, Output, Explanation.
4. Constraints MUST include at least 2 numeric bounds.
5. Both Code sections MUST be complete `def` functions — no placeholders.
6. Brute force MUST use a fundamentally different algorithm.
7. Both Time and Space Complexity are MANDATORY.''';
  }

  /// Builds a prompt for generating a problem similar in style and concept
  /// to [problemName], but entirely original — not a reproduction.
  static String buildPromptForSimilarProblem(
    String problemName,
    String category,
    String difficulty,
  ) {
    return '''You are an expert LeetCode problem designer. Generate a NEW $difficulty $category coding problem INSPIRED BY "$problemName" — same core technique, completely different theme and input scenario.

## Title
[A concise, descriptive problem title — not a renamed version of "$problemName"]

## Description
[A clear problem statement of at least 80 words. Different real-world setting from "$problemName". Define input, task, and expected output clearly.]

## Examples
Example 1:
Input: [actual input value]
Output: [actual output value]
Explanation: [why this output is correct]

Example 2:
Input: [edge case — empty, single element, duplicates, or negatives]
Output: [actual output value]
Explanation: [why this output is correct]

## Constraints
[Each constraint on its own line with numeric bounds, e.g.:
- 1 <= nums.length <= 10^5
- -10^4 <= nums[i] <= 10^4]

## Solution Approach
[Explain the optimal algorithm in 2-4 sentences using the $category technique.]

## Code
```python
def solution_function_name(param1, param2):
    """Complete, runnable Python optimal solution using $category technique."""
    # full implementation — no placeholders
    pass
```

## Time Complexity
O(...) — [one-sentence justification]

## Space Complexity
O(...) — [one-sentence justification]

## Brute Force Approach
[DIFFERENT algorithm from optimal — e.g., nested loops if optimal uses hash map. Explain why it is less efficient.]

## Brute Force Code
```python
def solution_brute_force(param1, param2):
    """Complete, runnable Python brute force — DIFFERENT algorithm from optimal."""
    # full implementation — no placeholders
    pass
```

STRICT REQUIREMENTS:
1. INSPIRED BY but NOT a reproduction of "$problemName" — different theme and scenario.
2. Core $category technique must be the same.
3. Description MUST be ≥ 80 words.
4. MUST include 2 Examples each with Input, Output, Explanation.
5. Constraints MUST include at least 2 numeric bounds.
6. Both Code sections MUST be complete `def` functions — no placeholders.
7. Brute force MUST use a fundamentally different algorithm.
8. Both Time and Space Complexity are MANDATORY.''';
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
    return '''You are an expert LeetCode problem designer. Generate a $difficulty $category coding problem. Follow EVERY requirement below exactly — no shortcuts.

## Title
[A concise, descriptive problem title]

## Description
[A clear problem statement of at least 80 words. Define the input, the task, and the expected output. Include context that makes the problem concrete.]

## Examples
Example 1:
Input: [actual input value]
Output: [actual output value]
Explanation: [why this output is correct]

Example 2:
Input: [different input, ideally an edge case — empty, single element, duplicates, or negatives]
Output: [actual output value]
Explanation: [why this output is correct]

## Constraints
[Each constraint on its own line. MUST include numeric bounds, e.g.:
- 1 <= nums.length <= 10^5
- -10^4 <= nums[i] <= 10^4]

## Solution Approach
[Explain the optimal algorithm in 2-4 sentences: the core insight, what data structure you use, and why it achieves the given complexity.]

## Code
```python
def solution_function_name(param1, param2):
    """Complete, runnable Python solution using the optimal approach."""
    # full implementation — no placeholders or '...'
    pass
```

## Time Complexity
O(...) — [one-sentence justification referencing the algorithm]

## Space Complexity
O(...) — [one-sentence justification]

## Brute Force Approach
[Describe a DIFFERENT, simpler algorithm — e.g., nested loops if optimal uses a hash map, or recursion without memoization if optimal uses DP. Must be a meaningfully different strategy.]

## Brute Force Code
```python
def solution_brute_force(param1, param2):
    """Complete, runnable Python brute force — uses a DIFFERENT algorithm from the optimal solution."""
    # full implementation — no placeholders or '...'
    pass
```

STRICT REQUIREMENTS — violating any of these will make the problem unusable:
1. Description MUST be ≥ 80 words with full context.
2. MUST include exactly 2 Examples, each with Input, Output, and Explanation.
3. Constraints MUST include at least 2 numeric bounds (e.g. 1 <= n <= 10^5).
4. Both Code sections MUST be complete, runnable Python functions starting with `def`.
5. The brute force MUST use a fundamentally different algorithm (not a minor variation of optimal).
6. Both Time and Space Complexity sections are MANDATORY.
7. Do NOT include any placeholder text such as "...", "TODO", or "your code here".''';
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
