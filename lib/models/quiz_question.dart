/// A multiple-choice knowledge-check question tied to a technique.
class QuizQuestion {
  final String question;
  final List<String> options; // exactly 4
  final int correctIndex;     // 0-based
  final String explanation;   // shown after answering

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
