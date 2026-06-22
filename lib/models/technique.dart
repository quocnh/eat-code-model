class TechniqueStep {
  final int stepNumber;
  final String title;
  final String description;

  const TechniqueStep({
    required this.stepNumber,
    required this.title,
    required this.description,
  });
}

class CodeExample {
  final String title;
  final String code;
  final String language;
  final String explanation;

  const CodeExample({
    required this.title,
    required this.code,
    required this.language,
    required this.explanation,
  });
}

class Technique {
  final String id;
  final String name;
  final String category;
  final String icon;
  final String shortDescription;
  final String fullDescription;
  final List<String> keyPatterns;
  final List<TechniqueStep> steps;
  final List<CodeExample> codeExamples;
  final String timeComplexity;
  final String spaceComplexity;
  final List<String> tips;
  final List<String> commonMistakes;
  final List<String> relatedProblems;
  final String difficulty;

  const Technique({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.shortDescription,
    required this.fullDescription,
    required this.keyPatterns,
    required this.steps,
    required this.codeExamples,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.tips,
    required this.commonMistakes,
    required this.relatedProblems,
    required this.difficulty,
  });
}
