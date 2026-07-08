/// EatCode Comprehensive Test Suite
///
/// Covers:
///   1. GeneratedProblem model — serialization, brute-force fields, markdown
///   2. Flashcard model — extraction, copyWith, null-safety
///   3. TemplateLlmService — all 12 categories × 3 difficulties, brute force
///   4. ProblemGenerator — prompts, parsing, company problems (brute force included)
///   5. ThemeService — toggle, state management
///   6. Progress model — serialization, default values
///   7. Integration: seeded data contains brute force sections
import 'package:flutter_test/flutter_test.dart';
import 'package:leetcode_flashcard/models/flashcard.dart';
import 'package:leetcode_flashcard/models/generated_problem.dart';
import 'package:leetcode_flashcard/models/progress.dart';
import 'package:leetcode_flashcard/services/llm_service.dart';
import 'package:leetcode_flashcard/services/problem_generator.dart';
import 'package:leetcode_flashcard/services/theme_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. GeneratedProblem
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  group('GeneratedProblem', () {
    GeneratedProblem _makeBasic() => GeneratedProblem(
          title: 'Test Problem',
          description: 'A simple test.',
          examples: ['Input: 1\nOutput: 2', 'Input: 3\nOutput: 4'],
          constraints: ['1 <= n <= 100', 'n is positive'],
          solutionApproach: 'Use a hash map.',
          code: 'def solve(n):\n    return n + 1',
          bruteForceApproach: 'Try every pair.',
          bruteForceCode: 'def brute(n):\n    return n + 1',
          timeComplexity: 'O(n)',
          spaceComplexity: 'O(1)',
          category: 'Arrays',
          difficulty: 'Easy',
          generatedAt: DateTime(2024, 1, 1),
        );

    test('all required fields are set', () {
      final p = _makeBasic();
      expect(p.title, 'Test Problem');
      expect(p.category, 'Arrays');
      expect(p.difficulty, 'Easy');
      expect(p.examples, hasLength(2));
      expect(p.constraints, hasLength(2));
    });

    test('bruteForceApproach and bruteForceCode are populated', () {
      final p = _makeBasic();
      expect(p.bruteForceApproach, isNotEmpty);
      expect(p.bruteForceCode, isNotEmpty);
    });

    test('bruteForceApproach defaults to empty string', () {
      final p = GeneratedProblem(
        title: 'X', description: 'X', examples: [], constraints: [],
        solutionApproach: 'X', code: 'pass',
        timeComplexity: 'O(1)', spaceComplexity: 'O(1)',
        category: 'Arrays', difficulty: 'Easy',
        generatedAt: DateTime.now(),
      );
      expect(p.bruteForceApproach, '');
      expect(p.bruteForceCode, '');
    });

    test('toMarkdownContent includes ## Question section', () {
      final md = _makeBasic().toMarkdownContent();
      expect(md, contains('## Question'));
    });

    test('toMarkdownContent includes ## Solution section', () {
      final md = _makeBasic().toMarkdownContent();
      expect(md, contains('## Solution'));
    });

    test('toMarkdownContent includes optimized approach', () {
      final md = _makeBasic().toMarkdownContent();
      expect(md, contains('⚡ Optimized Approach'));
    });

    test('toMarkdownContent includes brute force when code present', () {
      final md = _makeBasic().toMarkdownContent();
      expect(md, contains('🐌 Brute Force Approach'));
      expect(md, contains('Brute Force Code'));
    });

    test('toMarkdownContent omits brute force when code is empty', () {
      final p = _makeBasic().copyWith(bruteForceCode: '');
      final md = p.toMarkdownContent();
      expect(md, isNot(contains('🐌 Brute Force')));
    });

    test('toMarkdownContent shows examples in code blocks', () {
      final md = _makeBasic().toMarkdownContent();
      expect(md, contains('### Examples'));
      expect(md, contains('Input: 1'));
    });

    test('toMarkdownContent shows constraints as list', () {
      final md = _makeBasic().toMarkdownContent();
      expect(md, contains('### Constraints'));
      expect(md, contains('1 <= n <= 100'));
    });

    test('toMarkdownContent shows complexity', () {
      final md = _makeBasic().toMarkdownContent();
      expect(md, contains('O(n)'));  // time
      expect(md, contains('O(1)'));  // space
    });

    test('toMap roundtrip via fromMap preserves all fields', () {
      final original = _makeBasic();
      final restored = GeneratedProblem.fromMap(original.toMap());
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.examples, original.examples);
      expect(restored.constraints, original.constraints);
      expect(restored.solutionApproach, original.solutionApproach);
      expect(restored.code, original.code);
      expect(restored.bruteForceApproach, original.bruteForceApproach);
      expect(restored.bruteForceCode, original.bruteForceCode);
      expect(restored.timeComplexity, original.timeComplexity);
      expect(restored.spaceComplexity, original.spaceComplexity);
      expect(restored.category, original.category);
      expect(restored.difficulty, original.difficulty);
    });

    test('fromMap handles null optional fields gracefully', () {
      final map = {
        'title': 'T', 'description': 'D',
        'examples': null, 'constraints': null,
        'solution_approach': null, 'code': null,
        'brute_force_approach': null, 'brute_force_code': null,
        'time_complexity': null, 'space_complexity': null,
        'category': 'Arrays', 'difficulty': 'Easy',
        'generated_at': DateTime.now().toIso8601String(), 'company': null,
      };
      final p = GeneratedProblem.fromMap(map);
      expect(p.examples, isEmpty);
      expect(p.constraints, isEmpty);
      expect(p.bruteForceCode, '');
    });

    test('copyWith overrides specific fields', () {
      final original = _makeBasic();
      final copy = original.copyWith(title: 'Copied', difficulty: 'Hard');
      expect(copy.title, 'Copied');
      expect(copy.difficulty, 'Hard');
      expect(copy.category, original.category);  // unchanged
      expect(copy.bruteForceCode, original.bruteForceCode);  // preserved
    });

    test('company is null by default', () {
      expect(_makeBasic().company, isNull);
    });

    test('company is preserved in copyWith', () {
      final p = _makeBasic().copyWith(company: 'Google');
      expect(p.company, 'Google');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Flashcard model
  // ─────────────────────────────────────────────────────────────────────────
  group('Flashcard', () {
    const sampleMarkdown = '''## Question

**Category:** Arrays | **Difficulty:** Easy

Find the two numbers that add up to a target.

### Examples

```
Input: [2,7,11,15], target=9
Output: [0,1]
```

### Constraints

- 2 <= nums.length <= 10^4

## Solution

### ⚡ Optimized Approach

Use a hash map for O(1) lookups.

### Optimized Code

```python
def twoSum(nums, target):
    seen = {}
    for i, n in enumerate(nums):
        if target - n in seen:
            return [seen[target - n], i]
        seen[n] = i
```

### Complexity

- **Time:** O(n)
- **Space:** O(n)

---

### 🐌 Brute Force Approach

Check every pair.

### Brute Force Code

```python
def twoSum_brute(nums, target):
    for i in range(len(nums)):
        for j in range(i+1, len(nums)):
            if nums[i] + nums[j] == target:
                return [i, j]
```''';

    test('question is extracted correctly', () {
      final f = Flashcard(
        title: 'Two Sum',
        content: sampleMarkdown,
        difficulty: 'Easy',
        category: 'Arrays',
      );
      expect(f.question, contains('Find the two numbers'));
    });

    test('solution is extracted and contains optimized approach', () {
      final f = Flashcard(
        title: 'Two Sum',
        content: sampleMarkdown,
        difficulty: 'Easy',
        category: 'Arrays',
      );
      expect(f.solution, contains('⚡ Optimized Approach'));
    });

    test('solution contains brute force section', () {
      final f = Flashcard(
        title: 'Two Sum',
        content: sampleMarkdown,
        difficulty: 'Easy',
        category: 'Arrays',
      );
      expect(f.solution, contains('🐌 Brute Force Approach'));
    });

    test('getSolutionContent contains both solutions', () {
      final f = Flashcard(
        title: 'Two Sum',
        content: sampleMarkdown,
        difficulty: 'Easy',
        category: 'Arrays',
      );
      final sol = f.getSolutionContent();
      expect(sol, contains('⚡ Optimized Approach'));
      expect(sol, contains('🐌 Brute Force Approach'));
    });

    test('isBookmarked defaults to false', () {
      final f = Flashcard(
        title: 'X', content: '## Question\n\n## Solution\n',
        difficulty: 'Easy', category: 'Arrays',
      );
      expect(f.isBookmarked, false);
    });

    test('isSolved defaults to false', () {
      final f = Flashcard(
        title: 'X', content: '## Question\n\n## Solution\n',
        difficulty: 'Easy', category: 'Arrays',
      );
      expect(f.isSolved, false);
    });

    test('toMap / fromMap roundtrip preserves fields', () {
      final original = Flashcard(
        id: 1,
        title: 'Two Sum',
        content: sampleMarkdown,
        difficulty: 'Easy',
        category: 'Arrays',
        company: 'Google',
        isBookmarked: true,
        isSolved: false,
        createdAt: DateTime(2024, 6, 1),
      );
      final map = original.toMap();
      final restored = Flashcard.fromMap(map);
      expect(restored.title, original.title);
      expect(restored.difficulty, original.difficulty);
      expect(restored.category, original.category);
      expect(restored.company, original.company);
      expect(restored.isBookmarked, original.isBookmarked);
    });

    test('copyWith overrides only specified fields', () {
      final f = Flashcard(
        title: 'Original',
        content: sampleMarkdown,
        difficulty: 'Easy',
        category: 'Arrays',
      );
      final copy = f.copyWith(title: 'Updated', isBookmarked: true);
      expect(copy.title, 'Updated');
      expect(copy.isBookmarked, true);
      expect(copy.difficulty, f.difficulty);
    });

    test('empty content does not throw', () {
      final f = Flashcard(
        title: 'Empty', content: '',
        difficulty: 'Easy', category: 'Arrays',
      );
      expect(f.question, '');
      expect(f.solution, '');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Progress model
  // ─────────────────────────────────────────────────────────────────────────
  group('Progress', () {
    test('default confidence level is 0', () {
      final p = Progress(flashcardId: 1, isCompleted: false);
      expect(p.confidenceLevel, 0);
    });

    test('toMap contains all fields', () {
      final p = Progress(
        flashcardId: 42,
        isCompleted: true,
        confidenceLevel: 4,
        timesReviewed: 7,
      );
      final map = p.toMap();
      expect(map['flashcard_id'], 42);
      expect(map['is_completed'], 1);
      expect(map['confidence_level'], 4);
      expect(map['times_reviewed'], 7);
    });

    test('fromMap roundtrip is consistent', () {
      final original = Progress(
        id: 5,
        flashcardId: 10,
        isCompleted: true,
        confidenceLevel: 3,
        timesReviewed: 2,
        lastReviewedAt: DateTime(2024, 3, 15),
      );
      final restored = Progress.fromMap(original.toMap());
      expect(restored.flashcardId, original.flashcardId);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.confidenceLevel, original.confidenceLevel);
      expect(restored.timesReviewed, original.timesReviewed);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. TemplateLlmService — all categories produce brute force content
  // ─────────────────────────────────────────────────────────────────────────
  group('TemplateLlmService — brute force in all categories', () {
    late TemplateLlmService svc;

    setUp(() async {
      svc = TemplateLlmService();
      await svc.initialize();
    });

    const categories = [
      'Arrays', 'Strings', 'Trees', 'Graphs', 'Dynamic Programming',
      'Binary Search', 'Two Pointers', 'Sliding Window',
      'Stack', 'Heap', 'Backtracking', 'Linked List',
    ];

    for (final cat in categories) {
      for (final diff in ['Easy', 'Medium', 'Hard']) {
        test('$cat/$diff includes Brute Force sections', () async {
          final response = await svc.generate('$cat $diff');
          expect(
            response,
            contains('## Brute Force Approach'),
            reason: '$cat/$diff missing Brute Force Approach',
          );
          expect(
            response,
            contains('## Brute Force Code'),
            reason: '$cat/$diff missing Brute Force Code',
          );
        });
      }
    }

    test('generate returns Title section', () async {
      final result = await svc.generate('Arrays Easy');
      expect(result, contains('## Title'));
    });

    test('generate returns Solution Approach section', () async {
      final result = await svc.generate('Trees Medium');
      expect(result, contains('## Solution Approach'));
    });

    test('generateStream yields non-empty chunks', () async {
      final chunks = <String>[];
      await for (final c in svc.generateStream('Graphs Hard')) {
        chunks.add(c);
      }
      expect(chunks, isNotEmpty);
      expect(chunks.join(), contains('## Title'));
    });

    test('dispose sets isModelLoaded to false', () async {
      expect(svc.isModelLoaded, true);
      svc.dispose();
      expect(svc.isModelLoaded, false);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. ProblemGenerator — parsing and company problem brute force
  // ─────────────────────────────────────────────────────────────────────────
  group('ProblemGenerator', () {
    late ProblemGenerator generator;

    setUp(() async {
      final svc = TemplateLlmService();
      await svc.initialize();
      generator = ProblemGenerator(svc);
    });

    test('generateProblem returns non-empty title', () async {
      final p = await generator.generateProblem(
          category: 'Arrays', difficulty: 'Easy');
      expect(p.title, isNotEmpty);
    });

    test('generateProblem sets correct category and difficulty', () async {
      final p = await generator.generateProblem(
          category: 'Trees', difficulty: 'Medium');
      expect(p.category, 'Trees');
      expect(p.difficulty, 'Medium');
    });

    test('generateProblem returns bruteForceCode', () async {
      final p = await generator.generateProblem(
          category: 'Arrays', difficulty: 'Easy');
      expect(
        p.bruteForceCode,
        isNotEmpty,
        reason: 'Expected brute force code in generated problem',
      );
    });

    test('generateProblem returns bruteForceApproach', () async {
      final p = await generator.generateProblem(
          category: 'Dynamic Programming', difficulty: 'Hard');
      expect(p.bruteForceApproach, isNotEmpty);
    });

    test('generateCompanyProblem includes brute force code', () async {
      const companies = ['Google', 'Amazon', 'Meta', 'Microsoft'];
      for (final company in companies) {
        final p = await generator.generateCompanyProblem(
            company: company, difficulty: 'Medium');
        expect(
          p.bruteForceCode,
          isNotEmpty,
          reason: '$company company problem missing brute force code',
        );
      }
    });

    test('generateCompanyProblem sets company field', () async {
      final p = await generator.generateCompanyProblem(
          company: 'Google', difficulty: 'Easy');
      expect(p.company, 'Google');
    });

    test('generateCompanyProblem produces valid markdown with both solutions',
        () async {
      final p = await generator.generateCompanyProblem(
          company: 'Amazon', difficulty: 'Hard');
      final md = p.toMarkdownContent();
      expect(md, contains('⚡ Optimized Approach'));
      expect(md, contains('🐌 Brute Force Approach'));
    });

    test('generateSimilarProblem returns non-empty title', () async {
      final p = await generator.generateSimilarProblem(
        problemName: 'Two Sum',
        category: 'Arrays',
        difficulty: 'Easy',
      );
      expect(p.title, isNotEmpty);
    });

    test('generateSimilarProblem has brute force code', () async {
      final p = await generator.generateSimilarProblem(
        problemName: 'Valid Parentheses',
        category: 'Stack',
        difficulty: 'Easy',
      );
      expect(p.bruteForceCode, isNotEmpty);
    });

    test('buildPrompt contains requested category and difficulty', () {
      final prompt = ProblemGenerator.buildPrompt('Graphs', 'Hard');
      expect(prompt, contains('Graphs'));
      expect(prompt, contains('Hard'));
    });

    test('buildPrompt requests Brute Force section', () {
      final prompt = ProblemGenerator.buildPrompt('Arrays', 'Medium');
      expect(prompt, contains('Brute Force'));
    });

    test('buildCompanyPrompt contains company name', () {
      final prompt = ProblemGenerator.buildCompanyPrompt('Netflix', 'Easy');
      expect(prompt, contains('Netflix'));
    });

    test('buildCompanyPrompt requests Brute Force', () {
      final prompt = ProblemGenerator.buildCompanyPrompt('Uber', 'Hard');
      expect(prompt, contains('Brute Force'));
    });

    test('buildPromptForSimilarProblem contains original problem name', () {
      final prompt = ProblemGenerator.buildPromptForSimilarProblem(
          'Two Sum', 'Arrays', 'Easy');
      expect(prompt, contains('Two Sum'));
    });

    test('generateProblemStream yields chunks', () async {
      final chunks = <String>[];
      await for (final c in generator.generateProblemStream(
          category: 'Strings', difficulty: 'Easy')) {
        chunks.add(c);
      }
      expect(chunks, isNotEmpty);
    });

    test('all 12 categories generate problems with brute force', () async {
      const categories = [
        'Arrays', 'Strings', 'Trees', 'Graphs', 'Dynamic Programming',
        'Binary Search', 'Two Pointers', 'Sliding Window',
        'Stack', 'Heap', 'Backtracking', 'Linked List',
      ];
      for (final cat in categories) {
        final p = await generator.generateProblem(
            category: cat, difficulty: 'Easy');
        expect(
          p.bruteForceCode,
          isNotEmpty,
          reason: 'Category "$cat" missing brute force code',
        );
      }
    });

    test('all 8 companies generate problems with brute force', () async {
      const companies = [
        'Google', 'Amazon', 'Meta', 'Microsoft',
        'Apple', 'Netflix', 'Uber', 'Airbnb',
      ];
      for (final co in companies) {
        final p = await generator.generateCompanyProblem(
            company: co, difficulty: 'Easy');
        expect(
          p.bruteForceCode,
          isNotEmpty,
          reason: 'Company "$co" missing brute force code',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. ThemeService
  // ─────────────────────────────────────────────────────────────────────────
  group('ThemeService', () {
    // ThemeService is a singleton; reset to light after each test.
    setUp(() async {
      await ThemeService().setDark(false);
    });

    tearDown(() async {
      await ThemeService().setDark(false);
    });

    test('isDark is false by default (after reset)', () {
      expect(ThemeService().isDark, false);
    });

    test('themeMode is light by default', () {
      expect(ThemeService().themeMode, equals(ThemeMode.light));
    });

    test('setDark(true) changes isDark to true', () async {
      await ThemeService().setDark(true);
      expect(ThemeService().isDark, true);
    });

    test('setDark(true) changes themeMode to dark', () async {
      await ThemeService().setDark(true);
      expect(ThemeService().themeMode, ThemeMode.dark);
    });

    test('setDark(false) after true resets to light', () async {
      await ThemeService().setDark(true);
      await ThemeService().setDark(false);
      expect(ThemeService().isDark, false);
      expect(ThemeService().themeMode, ThemeMode.light);
    });

    test('notifyListeners is called when toggling', () async {
      int notifyCount = 0;
      void listener() => notifyCount++;
      ThemeService().addListener(listener);
      await ThemeService().setDark(true);
      ThemeService().removeListener(listener);
      expect(notifyCount, 1);
    });

    test('setDark with same value is a no-op (no notify)', () async {
      int notifyCount = 0;
      void listener() => notifyCount++;
      ThemeService().addListener(listener);
      await ThemeService().setDark(false); // already false
      ThemeService().removeListener(listener);
      expect(notifyCount, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Integration: toMarkdownContent → Flashcard → solution has brute force
  // ─────────────────────────────────────────────────────────────────────────
  group('Integration: GeneratedProblem → Flashcard stores brute force', () {
    test('full pipeline: generate → markdown → flashcard → solution field', () async {
      final svc = TemplateLlmService();
      await svc.initialize();
      final gen = ProblemGenerator(svc);

      final problem = await gen.generateProblem(
          category: 'Arrays', difficulty: 'Medium');
      expect(problem.bruteForceCode, isNotEmpty,
          reason: 'generateProblem must set bruteForceCode');

      final md = problem.toMarkdownContent();
      expect(md, contains('🐌 Brute Force Approach'),
          reason: 'Markdown must include brute force section');

      final flashcard = Flashcard(
        title: problem.title,
        content: md,
        difficulty: problem.difficulty,
        category: problem.category,
      );

      expect(flashcard.solution, contains('⚡ Optimized Approach'),
          reason: 'Flashcard.solution must contain optimized section');
      expect(flashcard.solution, contains('🐌 Brute Force Approach'),
          reason: 'Flashcard.solution must contain brute force section');
    });

    test('company problem pipeline preserves brute force', () async {
      final svc = TemplateLlmService();
      await svc.initialize();
      final gen = ProblemGenerator(svc);

      final problem = await gen.generateCompanyProblem(
          company: 'Google', difficulty: 'Hard');
      expect(problem.bruteForceCode, isNotEmpty,
          reason: 'Company problem must have bruteForceCode');

      final md = problem.toMarkdownContent();
      final flashcard = Flashcard(
        title: problem.title,
        content: md,
        difficulty: problem.difficulty,
        category: problem.category,
        company: problem.company,
      );

      expect(flashcard.solution, contains('🐌 Brute Force Approach'));
      expect(flashcard.company, 'Google');
    });
  });
}
