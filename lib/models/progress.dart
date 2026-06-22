class Progress {
  final int? id;
  final int flashcardId;
  final bool isCompleted;
  final int confidenceLevel;
  final int timesReviewed;
  final DateTime? lastReviewedAt;

  Progress({
    this.id,
    required this.flashcardId,
    this.isCompleted = false,
    this.confidenceLevel = 0,
    this.timesReviewed = 0,
    this.lastReviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flashcard_id': flashcardId,
      'is_completed': isCompleted ? 1 : 0,
      'confidence_level': confidenceLevel,
      'times_reviewed': timesReviewed,
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
    };
  }

  factory Progress.fromMap(Map<String, dynamic> map) {
    return Progress(
      id: map['id'] as int?,
      flashcardId: map['flashcard_id'] as int,
      isCompleted: map['is_completed'] == 1,
      confidenceLevel: map['confidence_level'] as int,
      timesReviewed: map['times_reviewed'] as int,
      lastReviewedAt: map['last_reviewed_at'] != null 
        ? DateTime.parse(map['last_reviewed_at'] as String)
        : null,
    );
  }

  Progress copyWith({
    int? id,
    int? flashcardId,
    bool? isCompleted,
    int? confidenceLevel,
    int? timesReviewed,
    DateTime? lastReviewedAt,
  }) {
    return Progress(
      id: id ?? this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      isCompleted: isCompleted ?? this.isCompleted,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}