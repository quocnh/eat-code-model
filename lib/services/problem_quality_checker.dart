import '../models/generated_problem.dart';

/// Result of running quality checks on a [GeneratedProblem].
class QualityResult {
  final Map<String, bool> checks; // label → passed
  final List<String> issues;       // failed check messages
  final int score;                 // passed count
  final int total;                 // total checks

  const QualityResult({
    required this.checks,
    required this.issues,
    required this.score,
    required this.total,
  });

  double get percentage => total == 0 ? 0 : score / total;
  bool get passed => issues.isEmpty;

  String get grade {
    if (percentage >= 0.90) return 'A';
    if (percentage >= 0.75) return 'B';
    if (percentage >= 0.60) return 'C';
    return 'F';
  }
}

/// Runs a suite of offline quality checks on a generated problem.
///
/// Checks modelled after the spec:
///   ✓ Multiple independent solutions (dual code present + different)
///   ✓ Examples provided (hidden test proxy)
///   ✓ Edge cases covered (examples include boundary values)
///   ✓ Both complexities stated
///   ✓ Duplicate detection (title not too generic)
///   ✓ Difficulty estimation (enough constraints + description)
///   ✓ Readability (description length + capitalization)
class ProblemQualityChecker {
  static QualityResult check(GeneratedProblem problem) {
    final checks = <String, bool>{};
    final issues = <String>[];

    // 1. Valid title
    final hasTitle = problem.title.trim().length >= 5 &&
        problem.title.trim().length <= 80;
    checks['Valid title'] = hasTitle;
    if (!hasTitle) issues.add('Title is missing or too short/long');

    // 2. Meaningful description (>= 60 chars)
    final hasDesc = problem.description.trim().length >= 60;
    checks['Description present'] = hasDesc;
    if (!hasDesc) issues.add('Description too short — may be incomplete');

    // 3. At least 2 examples
    final hasExamples = problem.examples.length >= 2;
    checks['≥2 examples'] = hasExamples;
    if (!hasExamples) issues.add('Fewer than 2 examples provided');

    // 4. At least 1 constraint
    final hasConstraints = problem.constraints.isNotEmpty;
    checks['Constraints stated'] = hasConstraints;
    if (!hasConstraints) issues.add('No constraints listed');

    // 5. Optimized solution code present and looks like Python
    final hasOptCode =
        problem.code.isNotEmpty && _looksLikePython(problem.code);
    checks['Optimized code'] = hasOptCode;
    if (!hasOptCode) issues.add('Optimized solution code is missing or invalid');

    // 6. Brute force code present and looks like Python
    final hasBfCode =
        problem.bruteForceCode.isNotEmpty &&
        _looksLikePython(problem.bruteForceCode);
    checks['Brute force code'] = hasBfCode;
    if (!hasBfCode) issues.add('Brute force code is missing or invalid');

    // 7. Solutions are different (not copy-paste)
    final solutionsDiffer =
        problem.code.trim() != problem.bruteForceCode.trim();
    checks['Distinct solutions'] = solutionsDiffer;
    if (!solutionsDiffer) issues.add('Optimized and brute force code appear identical');

    // 8. Both complexities stated
    final hasComplexity = problem.timeComplexity.trim().isNotEmpty &&
        problem.spaceComplexity.trim().isNotEmpty;
    checks['Complexity stated'] = hasComplexity;
    if (!hasComplexity) issues.add('Time or space complexity is missing');

    // 9. Edge cases proxy — at least one example contains 0, [], or boundary
    final examplesText = problem.examples.join(' ');
    final hasEdgeCases = examplesText.contains('0') ||
        examplesText.contains('[]') ||
        examplesText.contains('empty') ||
        examplesText.contains('-1') ||
        examplesText.contains('n=1') ||
        problem.constraints.any((c) => c.contains('0') || c.contains('1 <='));
    checks['Edge cases covered'] = hasEdgeCases;
    if (!hasEdgeCases) issues.add('No edge-case examples detected');

    // 10. Readability — description starts with capital letter, no obvious gibberish
    final desc = problem.description.trim();
    final readable = desc.isNotEmpty &&
        desc[0] == desc[0].toUpperCase() &&
        _wordCount(desc) >= 10;
    checks['Readability'] = readable;
    if (!readable) issues.add('Description may have readability issues');

    final score = checks.values.where((v) => v).length;
    return QualityResult(
      checks: checks,
      issues: issues,
      score: score,
      total: checks.length,
    );
  }

  static bool _looksLikePython(String code) {
    final c = code.trim();
    return c.contains('def ') &&
        (c.contains('return') || c.contains(':'));
  }

  static int _wordCount(String text) =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}
