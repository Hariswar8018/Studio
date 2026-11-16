class SrsProgressModel {
  static const List<int> intervalsInDays = [1, 2, 4, 8, 12];

  final String id; // Unique: '${userId}_${topicId}_${questionId}'
  final String userId;
  final String topicId;
  final int questionId;
  final String jlpt;
  final int stage; // 1=1 day, 2=2 days, 3=4 days, 4=8 days, 5=12 days, 6=mastered
  final DateTime nextReviewDate;
  final DateTime lastReviewedDate;
  final int correctCount;
  final int wrongCount;
  final bool isMastered;

  SrsProgressModel({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.questionId,
    required this.jlpt,
    this.stage = 1,
    required this.nextReviewDate,
    required this.lastReviewedDate,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.isMastered = false,
  });

  bool get isDue =>
      DateTime.now().isAfter(nextReviewDate) ||
      DateTime.now().isAtSameMomentAs(nextReviewDate);

  int get intervalDays {
    if (stage <= 0) return 1;
    if (stage > intervalsInDays.length) return 12;
    return intervalsInDays[stage - 1];
  }

  /// Needs 10+ correct tests to become an Easy Word / Mastered Grammar
  bool get isEasy => correctCount >= 10;
  bool get isMasteredEasy => isEasy;

  /// If user did wrong even once, or hasn't reached 10 correct, it is in Difficult Grammar
  bool get isDifficult => (wrongCount > 0 && correctCount < 10);

  SrsProgressModel copyWithResult({required bool isCorrect}) {
    final now = DateTime.now();
    int newCorrect = correctCount;
    int newWrong = wrongCount;
    int newStage = stage;

    if (isCorrect) {
      newCorrect++;
      newStage = stage + 1;
    } else {
      newWrong++;
      // Demote to stage 1 (1 day interval) on error for immediate spaced repetition
      newStage = 1;
    }

    // A sentence grammar needs 10+ correct tests to be marked Easy / Mastered
    final bool mastered = newCorrect >= 10;
    final int nextInterval = mastered ? 14 : intervalsInDays[newStage > intervalsInDays.length ? intervalsInDays.length - 1 : newStage - 1];
    final DateTime nextDate = now.add(Duration(days: nextInterval));

    return SrsProgressModel(
      id: id,
      userId: userId,
      topicId: topicId,
      questionId: questionId,
      jlpt: jlpt,
      stage: newStage,
      nextReviewDate: nextDate,
      lastReviewedDate: now,
      correctCount: newCorrect,
      wrongCount: newWrong,
      isMastered: mastered,
    );
  }

  factory SrsProgressModel.fromMap(Map<String, dynamic> map, String docId) {
    return SrsProgressModel(
      id: docId,
      userId: map['userId']?.toString() ?? '',
      topicId: map['topicId']?.toString() ?? '',
      questionId: map['questionId'] is int
          ? map['questionId']
          : int.tryParse(map['questionId']?.toString() ?? '0') ?? 0,
      jlpt: (map['jlpt']?.toString() ?? 'N3').toUpperCase(),
      stage: map['stage'] is int
          ? map['stage']
          : int.tryParse(map['stage']?.toString() ?? '1') ?? 1,
      nextReviewDate: map['nextReviewDate'] != null
          ? DateTime.tryParse(map['nextReviewDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastReviewedDate: map['lastReviewedDate'] != null
          ? DateTime.tryParse(map['lastReviewedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      correctCount: map['correctCount'] is int
          ? map['correctCount']
          : int.tryParse(map['correctCount']?.toString() ?? '0') ?? 0,
      wrongCount: map['wrongCount'] is int
          ? map['wrongCount']
          : int.tryParse(map['wrongCount']?.toString() ?? '0') ?? 0,
      isMastered: map['isMastered'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'topicId': topicId,
      'questionId': questionId,
      'jlpt': jlpt,
      'stage': stage,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'lastReviewedDate': lastReviewedDate.toIso8601String(),
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'isMastered': isMastered,
    };
  }
}
