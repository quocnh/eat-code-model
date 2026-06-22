import 'package:flutter_test/flutter_test.dart';
import 'package:leetcode_flashcard/models/technique.dart';
import 'package:leetcode_flashcard/data/training_data.dart';

void main() {
  group('TrainingData', () {
    test('techniques list is not empty', () {
      expect(TrainingData.techniques, isNotEmpty);
    });

    test('techniques list has 15 entries', () {
      expect(TrainingData.techniques.length, 15);
    });

    test('all techniques have non-empty id', () {
      for (final t in TrainingData.techniques) {
        expect(t.id, isNotEmpty,
            reason: 'Technique "${t.name}" has empty id');
      }
    });

    test('all techniques have non-empty name', () {
      for (final t in TrainingData.techniques) {
        expect(t.name, isNotEmpty,
            reason: 'Technique with id "${t.id}" has empty name');
      }
    });

    test('all techniques have non-empty category', () {
      for (final t in TrainingData.techniques) {
        expect(t.category, isNotEmpty,
            reason: 'Technique "${t.name}" has empty category');
      }
    });

    test('all techniques have non-empty shortDescription', () {
      for (final t in TrainingData.techniques) {
        expect(t.shortDescription, isNotEmpty,
            reason: 'Technique "${t.name}" has empty shortDescription');
      }
    });

    test('all techniques have non-empty fullDescription', () {
      for (final t in TrainingData.techniques) {
        expect(t.fullDescription, isNotEmpty,
            reason: 'Technique "${t.name}" has empty fullDescription');
      }
    });

    test('all techniques have at least one key pattern', () {
      for (final t in TrainingData.techniques) {
        expect(t.keyPatterns, isNotEmpty,
            reason: 'Technique "${t.name}" has no key patterns');
      }
    });

    test('all techniques have at least one step', () {
      for (final t in TrainingData.techniques) {
        expect(t.steps, isNotEmpty,
            reason: 'Technique "${t.name}" has no steps');
      }
    });

    test('all techniques have non-empty relatedProblems', () {
      for (final t in TrainingData.techniques) {
        expect(t.relatedProblems, isNotEmpty,
            reason: 'Technique "${t.name}" has no related problems');
      }
    });

    test('all techniques have non-empty timeComplexity', () {
      for (final t in TrainingData.techniques) {
        expect(t.timeComplexity, isNotEmpty,
            reason: 'Technique "${t.name}" has empty timeComplexity');
      }
    });

    test('all techniques have non-empty spaceComplexity', () {
      for (final t in TrainingData.techniques) {
        expect(t.spaceComplexity, isNotEmpty,
            reason: 'Technique "${t.name}" has empty spaceComplexity');
      }
    });

    test('all technique ids are unique', () {
      final ids = TrainingData.techniques.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate technique ids found');
    });

    test('all technique categories are valid', () {
      const validCategories = {
        'Fundamental',
        'Tree/Graph',
        'Advanced',
        'Optimization',
      };
      for (final t in TrainingData.techniques) {
        expect(validCategories, contains(t.category),
            reason:
                'Technique "${t.name}" has invalid category "${t.category}"');
      }
    });

    test('all technique difficulties are valid', () {
      const validDifficulties = {'Beginner', 'Intermediate', 'Advanced'};
      for (final t in TrainingData.techniques) {
        expect(validDifficulties, contains(t.difficulty),
            reason:
                'Technique "${t.name}" has invalid difficulty "${t.difficulty}"');
      }
    });

    test('all techniques have non-empty icon', () {
      for (final t in TrainingData.techniques) {
        expect(t.icon, isNotEmpty,
            reason: 'Technique "${t.name}" has empty icon');
      }
    });

    test('all steps have sequential stepNumber starting from 1', () {
      for (final t in TrainingData.techniques) {
        for (int i = 0; i < t.steps.length; i++) {
          expect(t.steps[i].stepNumber, i + 1,
              reason:
                  'Step ${i + 1} of "${t.name}" has wrong stepNumber ${t.steps[i].stepNumber}');
        }
      }
    });

    test('all steps have non-empty title', () {
      for (final t in TrainingData.techniques) {
        for (final step in t.steps) {
          expect(step.title, isNotEmpty,
              reason: 'A step in "${t.name}" has empty title');
        }
      }
    });

    test('all steps have non-empty description', () {
      for (final t in TrainingData.techniques) {
        for (final step in t.steps) {
          expect(step.description, isNotEmpty,
              reason: 'A step in "${t.name}" has empty description');
        }
      }
    });

    test('getByCategory returns only Fundamental techniques', () {
      final fundamental = TrainingData.getByCategory('Fundamental');
      expect(fundamental, isNotEmpty);
      expect(fundamental.every((t) => t.category == 'Fundamental'), true);
    });

    test('getByCategory returns only Tree/Graph techniques', () {
      final treeGraph = TrainingData.getByCategory('Tree/Graph');
      expect(treeGraph, isNotEmpty);
      expect(treeGraph.every((t) => t.category == 'Tree/Graph'), true);
    });

    test('getByCategory returns only Advanced techniques', () {
      final advanced = TrainingData.getByCategory('Advanced');
      expect(advanced, isNotEmpty);
      expect(advanced.every((t) => t.category == 'Advanced'), true);
    });

    test('getByCategory returns only Optimization techniques', () {
      final optimization = TrainingData.getByCategory('Optimization');
      expect(optimization, isNotEmpty);
      expect(optimization.every((t) => t.category == 'Optimization'), true);
    });

    test('getByCategory returns empty list for unknown category', () {
      final result = TrainingData.getByCategory('Nonexistent');
      expect(result, isEmpty);
    });

    test('getById returns correct technique for two-pointers', () {
      final t = TrainingData.getById('two-pointers');
      expect(t, isNotNull);
      expect(t!.id, 'two-pointers');
    });

    test('getById returns correct technique for sliding-window', () {
      final t = TrainingData.getById('sliding-window');
      expect(t, isNotNull);
      expect(t!.id, 'sliding-window');
    });

    test('getById returns correct technique for binary-search', () {
      final t = TrainingData.getById('binary-search');
      expect(t, isNotNull);
      expect(t!.id, 'binary-search');
    });

    test('getById returns correct technique for dp-1d', () {
      final t = TrainingData.getById('dp-1d');
      expect(t, isNotNull);
      expect(t!.id, 'dp-1d');
    });

    test('getById returns correct technique for dp-2d', () {
      final t = TrainingData.getById('dp-2d');
      expect(t, isNotNull);
      expect(t!.id, 'dp-2d');
    });

    test('getById returns correct technique for stack', () {
      final t = TrainingData.getById('stack');
      expect(t, isNotNull);
      expect(t!.id, 'stack');
    });

    test('getById returns correct technique for heap', () {
      final t = TrainingData.getById('heap');
      expect(t, isNotNull);
      expect(t!.id, 'heap');
    });

    test('getById returns correct technique for hashmap', () {
      final t = TrainingData.getById('hashmap');
      expect(t, isNotNull);
      expect(t!.id, 'hashmap');
    });

    test('getById returns correct technique for greedy', () {
      final t = TrainingData.getById('greedy');
      expect(t, isNotNull);
      expect(t!.id, 'greedy');
    });

    test('getById returns correct technique for trie', () {
      final t = TrainingData.getById('trie');
      expect(t, isNotNull);
      expect(t!.id, 'trie');
    });

    test('getById returns correct technique for union-find', () {
      final t = TrainingData.getById('union-find');
      expect(t, isNotNull);
      expect(t!.id, 'union-find');
    });

    test('getById returns correct technique for monotonic-stack', () {
      final t = TrainingData.getById('monotonic-stack');
      expect(t, isNotNull);
      expect(t!.id, 'monotonic-stack');
    });

    test('getById returns null for unknown id', () {
      final t = TrainingData.getById('nonexistent');
      expect(t, isNull);
    });

    test('getById returns null for empty string', () {
      final t = TrainingData.getById('');
      expect(t, isNull);
    });

    test('Fundamental category count is correct', () {
      // two-pointers, sliding-window, binary-search, stack, hashmap, linked-list = 6
      final fundamental = TrainingData.getByCategory('Fundamental');
      expect(fundamental.length, 6);
    });

    test('Tree/Graph category count is correct', () {
      // bfs-trees, dfs-backtracking = 2
      final treeGraph = TrainingData.getByCategory('Tree/Graph');
      expect(treeGraph.length, 2);
    });

    test('Advanced category count is correct', () {
      // dp-1d, dp-2d, heap, trie, union-find, monotonic-stack = 6
      final advanced = TrainingData.getByCategory('Advanced');
      expect(advanced.length, 6);
    });

    test('Optimization category count is correct', () {
      // greedy = 1
      final optimization = TrainingData.getByCategory('Optimization');
      expect(optimization.length, 1);
    });
  });

  group('Technique model', () {
    const step = TechniqueStep(
      stepNumber: 1,
      title: 'Initialize',
      description: 'Initialize the pointers',
    );

    const example = CodeExample(
      title: 'Hello World',
      code: 'print("hello")',
      language: 'python',
      explanation: 'Prints hello to stdout',
    );

    const technique = Technique(
      id: 'test-technique',
      name: 'Test Technique',
      category: 'Fundamental',
      icon: '🧪',
      shortDescription: 'A short description',
      fullDescription: 'A full description of the technique',
      keyPatterns: ['Pattern A', 'Pattern B'],
      steps: [step],
      codeExamples: [example],
      timeComplexity: 'O(n)',
      spaceComplexity: 'O(1)',
      tips: ['Tip 1', 'Tip 2'],
      commonMistakes: ['Mistake 1'],
      relatedProblems: ['Problem 1 (LeetCode 1)'],
      difficulty: 'Beginner',
    );

    test('technique id is accessible', () {
      expect(technique.id, 'test-technique');
    });

    test('technique name is accessible', () {
      expect(technique.name, 'Test Technique');
    });

    test('technique category is accessible', () {
      expect(technique.category, 'Fundamental');
    });

    test('technique icon is accessible', () {
      expect(technique.icon, '🧪');
    });

    test('technique shortDescription is accessible', () {
      expect(technique.shortDescription, 'A short description');
    });

    test('technique fullDescription is accessible', () {
      expect(technique.fullDescription, 'A full description of the technique');
    });

    test('technique keyPatterns are accessible', () {
      expect(technique.keyPatterns, ['Pattern A', 'Pattern B']);
    });

    test('technique steps are accessible', () {
      expect(technique.steps.length, 1);
      expect(technique.steps.first.title, 'Initialize');
    });

    test('technique step description is accessible', () {
      expect(technique.steps.first.description, 'Initialize the pointers');
    });

    test('technique step number is accessible', () {
      expect(technique.steps.first.stepNumber, 1);
    });

    test('technique codeExamples are accessible', () {
      expect(technique.codeExamples.length, 1);
      expect(technique.codeExamples.first.code, 'print("hello")');
    });

    test('technique codeExample language is accessible', () {
      expect(technique.codeExamples.first.language, 'python');
    });

    test('technique codeExample explanation is accessible', () {
      expect(technique.codeExamples.first.explanation, 'Prints hello to stdout');
    });

    test('technique timeComplexity is accessible', () {
      expect(technique.timeComplexity, 'O(n)');
    });

    test('technique spaceComplexity is accessible', () {
      expect(technique.spaceComplexity, 'O(1)');
    });

    test('technique tips are accessible', () {
      expect(technique.tips, ['Tip 1', 'Tip 2']);
    });

    test('technique commonMistakes are accessible', () {
      expect(technique.commonMistakes, ['Mistake 1']);
    });

    test('technique relatedProblems are accessible', () {
      expect(technique.relatedProblems, ['Problem 1 (LeetCode 1)']);
    });

    test('technique difficulty is accessible', () {
      expect(technique.difficulty, 'Beginner');
    });
  });

  group('TechniqueStep model', () {
    const step = TechniqueStep(
      stepNumber: 3,
      title: 'Finalize',
      description: 'Return the result',
    );

    test('stepNumber is correct', () {
      expect(step.stepNumber, 3);
    });

    test('title is correct', () {
      expect(step.title, 'Finalize');
    });

    test('description is correct', () {
      expect(step.description, 'Return the result');
    });
  });

  group('CodeExample model', () {
    const example = CodeExample(
      title: 'Sort Example',
      code: 'nums.sort()',
      language: 'python',
      explanation: 'Sorts the list in-place',
    );

    test('title is correct', () {
      expect(example.title, 'Sort Example');
    });

    test('code is correct', () {
      expect(example.code, 'nums.sort()');
    });

    test('language is correct', () {
      expect(example.language, 'python');
    });

    test('explanation is correct', () {
      expect(example.explanation, 'Sorts the list in-place');
    });
  });
}
