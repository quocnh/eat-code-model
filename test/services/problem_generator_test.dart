import 'package:flutter_test/flutter_test.dart';
import 'package:leetcode_flashcard/services/llm_service.dart';
import 'package:leetcode_flashcard/services/problem_generator.dart';
import 'package:leetcode_flashcard/models/generated_problem.dart';

void main() {
  group('TemplateLlmService', () {
    late TemplateLlmService service;

    setUp(() {
      service = TemplateLlmService();
    });

    test('isModelLoaded is false before initialize', () {
      expect(service.isModelLoaded, false);
    });

    test('isModelLoaded is true after initialize', () async {
      await service.initialize();
      expect(service.isModelLoaded, true);
    });

    test('generate returns non-empty string', () async {
      await service.initialize();
      final result =
          await service.generate('Generate a problem about Arrays Easy');
      expect(result, isNotEmpty);
    });

    test('generate returns string containing title section', () async {
      await service.initialize();
      final result = await service.generate('Arrays Medium');
      expect(result, contains('## Title'));
    });

    test('generateStream yields chunks', () async {
      await service.initialize();
      final chunks = <String>[];
      await for (final chunk in service.generateStream('Arrays Easy')) {
        chunks.add(chunk);
      }
      expect(chunks, isNotEmpty);
    });

    test('generateStream concatenates to non-empty string', () async {
      await service.initialize();
      final buffer = StringBuffer();
      await for (final chunk in service.generateStream('Strings Medium')) {
        buffer.write(chunk);
      }
      expect(buffer.toString(), isNotEmpty);
    });

    test('generate handles Trees category', () async {
      await service.initialize();
      final result = await service.generate('Generate Trees Hard problem');
      expect(result, isNotEmpty);
    });

    test('generate handles Dynamic Programming category', () async {
      await service.initialize();
      final result =
          await service.generate('Generate a Dynamic Programming Easy problem');
      expect(result, isNotEmpty);
    });

    test('generate handles Graphs category', () async {
      await service.initialize();
      final result = await service.generate('Graphs Medium');
      expect(result, isNotEmpty);
    });

    test('generate handles unknown category gracefully', () async {
      await service.initialize();
      // Should fall back to Arrays template without throwing.
      final result = await service.generate('Unknown category problem');
      expect(result, isNotEmpty);
    });

    test('dispose sets isModelLoaded to false', () async {
      await service.initialize();
      expect(service.isModelLoaded, true);
      service.dispose();
      expect(service.isModelLoaded, false);
    });
  });

  group('ProblemGenerator', () {
    late ProblemGenerator generator;

    setUp(() async {
      final service = TemplateLlmService();
      await service.initialize();
      generator = ProblemGenerator(service);
    });

    test('buildPrompt contains category', () {
      final prompt = ProblemGenerator.buildPrompt('Arrays', 'Easy');
      expect(prompt, contains('Arrays'));
    });

    test('buildPrompt contains difficulty', () {
      final prompt = ProblemGenerator.buildPrompt('Arrays', 'Easy');
      expect(prompt, contains('Easy'));
    });

    test('buildPrompt contains both category and difficulty', () {
      final prompt =
          ProblemGenerator.buildPrompt('Dynamic Programming', 'Hard');
      expect(prompt, contains('Dynamic Programming'));
      expect(prompt, contains('Hard'));
    });

    test('generateProblem returns GeneratedProblem with correct category',
        () async {
      final problem = await generator.generateProblem(
          category: 'Arrays', difficulty: 'Easy');
      expect(problem.category, 'Arrays');
    });

    test('generateProblem returns GeneratedProblem with correct difficulty',
        () async {
      final problem = await generator.generateProblem(
          category: 'Arrays', difficulty: 'Easy');
      expect(problem.difficulty, 'Easy');
    });

    test('generateProblem returns non-empty title', () async {
      final problem = await generator.generateProblem(
          category: 'Arrays', difficulty: 'Medium');
      expect(problem.title, isNotEmpty);
    });

    test('generateProblem returns non-empty description', () async {
      final problem = await generator.generateProblem(
          category: 'Strings', difficulty: 'Hard');
      expect(problem.description, isNotEmpty);
    });

    test('generateProblem returns a generatedAt timestamp', () async {
      final before = DateTime.now();
      final problem = await generator.generateProblem(
          category: 'Trees', difficulty: 'Medium');
      final after = DateTime.now();
      expect(
          problem.generatedAt
              .isAfter(before.subtract(const Duration(seconds: 1))),
          true);
      expect(
          problem.generatedAt
              .isBefore(after.add(const Duration(seconds: 1))),
          true);
    });

    test('generateProblemStream yields text', () async {
      final chunks = <String>[];
      await for (final chunk in generator.generateProblemStream(
          category: 'Strings', difficulty: 'Medium')) {
        chunks.add(chunk);
      }
      expect(chunks, isNotEmpty);
    });

    test('generateProblemStream output is non-empty', () async {
      final buffer = StringBuffer();
      await for (final chunk in generator.generateProblemStream(
          category: 'Binary Search', difficulty: 'Easy')) {
        buffer.write(chunk);
      }
      expect(buffer.toString(), isNotEmpty);
    });

    test('generateProblem works for Graphs category', () async {
      final problem = await generator.generateProblem(
          category: 'Graphs', difficulty: 'Medium');
      expect(problem.category, 'Graphs');
      expect(problem.title, isNotEmpty);
    });

    test('generateProblem works for Stack category', () async {
      final problem = await generator.generateProblem(
          category: 'Stack', difficulty: 'Easy');
      expect(problem.category, 'Stack');
    });
  });

  group('GeneratedProblem', () {
    late GeneratedProblem problem;

    setUp(() {
      problem = GeneratedProblem(
        title: 'Two Sum',
        description: 'Find two numbers that add up to target',
        examples: const ['Input: [2,7,11,15], target=9 → Output: [0,1]'],
        constraints: const ['2 <= nums.length <= 10^4'],
        solutionApproach: 'Use a hash map',
        code: 'def twoSum(nums, target): ...',
        timeComplexity: 'O(n)',
        spaceComplexity: 'O(n)',
        category: 'Arrays',
        difficulty: 'Easy',
        generatedAt: DateTime(2024, 1, 1),
      );
    });

    test('toMarkdownContent contains ## Question section', () {
      final md = problem.toMarkdownContent();
      expect(md, contains('## Question'));
    });

    test('toMarkdownContent contains ## Solution section', () {
      final md = problem.toMarkdownContent();
      expect(md, contains('## Solution'));
    });

    test(
        'toMarkdownContent contains the problem description in the question section',
        () {
      final md = problem.toMarkdownContent();
      // Description should appear before ## Solution
      final questionPart = md.split('## Solution')[0];
      expect(questionPart, contains('Find two numbers'));
    });

    test('toMarkdownContent contains code', () {
      final md = problem.toMarkdownContent();
      expect(md, contains('def twoSum'));
    });

    test('toMarkdownContent contains time complexity', () {
      final md = problem.toMarkdownContent();
      expect(md, contains('O(n)'));
    });

    test('toMarkdownContent contains category and difficulty metadata', () {
      final md = problem.toMarkdownContent();
      expect(md, contains('Arrays'));
      expect(md, contains('Easy'));
    });

    test('toMap roundtrip preserves title', () {
      final map = problem.toMap();
      final restored = GeneratedProblem.fromMap(map);
      expect(restored.title, problem.title);
    });

    test('toMap roundtrip preserves category', () {
      final map = problem.toMap();
      final restored = GeneratedProblem.fromMap(map);
      expect(restored.category, problem.category);
    });

    test('toMap roundtrip preserves difficulty', () {
      final map = problem.toMap();
      final restored = GeneratedProblem.fromMap(map);
      expect(restored.difficulty, problem.difficulty);
    });

    test('toMap roundtrip preserves examples', () {
      final map = problem.toMap();
      final restored = GeneratedProblem.fromMap(map);
      expect(restored.examples, problem.examples);
    });

    test('toMap roundtrip preserves constraints', () {
      final map = problem.toMap();
      final restored = GeneratedProblem.fromMap(map);
      expect(restored.constraints, problem.constraints);
    });

    test('toMap roundtrip preserves solutionApproach', () {
      final map = problem.toMap();
      final restored = GeneratedProblem.fromMap(map);
      expect(restored.solutionApproach, problem.solutionApproach);
    });

    test('toMap roundtrip preserves generatedAt', () {
      final map = problem.toMap();
      final restored = GeneratedProblem.fromMap(map);
      expect(restored.generatedAt, problem.generatedAt);
    });

    test('copyWith updates specified field', () {
      final copy = problem.copyWith(difficulty: 'Hard');
      expect(copy.difficulty, 'Hard');
    });

    test('copyWith preserves unspecified fields', () {
      final copy = problem.copyWith(difficulty: 'Hard');
      expect(copy.title, problem.title);
      expect(copy.category, problem.category);
      expect(copy.description, problem.description);
    });

    test('copyWith with new category preserves title', () {
      final copy = problem.copyWith(category: 'Graphs');
      expect(copy.category, 'Graphs');
      expect(copy.title, problem.title);
    });

    test('copyWith with new title preserves difficulty', () {
      final copy = problem.copyWith(title: 'Three Sum');
      expect(copy.title, 'Three Sum');
      expect(copy.difficulty, problem.difficulty);
    });

    test('fromMap handles missing optional keys gracefully', () {
      final sparse = <String, dynamic>{
        'title': 'Sparse Problem',
        'category': 'Trees',
        'difficulty': 'Easy',
        'generated_at': DateTime(2024, 1, 1).toIso8601String(),
      };
      final restored = GeneratedProblem.fromMap(sparse);
      expect(restored.title, 'Sparse Problem');
      expect(restored.description, '');
      expect(restored.examples, isEmpty);
      expect(restored.constraints, isEmpty);
      expect(restored.code, '');
    });
  });
}
