import 'package:flutter_test/flutter_test.dart';
import 'package:grammar_app/data/sample_grammar_data.dart';
import 'package:grammar_app/models/grammar_model.dart';
import 'package:grammar_app/models/srs_progress_model.dart';

void main() {
  group('Grammar App Model & SRS Tests', () {
    test('JSON parses N3 purpose topic correctly with 25 questions', () {
      final sampleMap = SampleGrammarData.getSampleN3Purpose();
      final topic = GrammarTopicModel.fromJson(sampleMap);

      expect(topic.id, equals('grammar_purpose_001'));
      expect(topic.title, equals('ように vs ために vs ようにする'));
      expect(topic.jlpt, equals('N3'));
      expect(topic.category, equals('Purpose and Intention'));
      expect(topic.globalOptions.length, equals(3));
      expect(topic.globalOptions.containsKey('A'), isTrue);
      expect(topic.globalOptions.containsKey('B'), isTrue);
      expect(topic.globalOptions.containsKey('C'), isTrue);
      expect(topic.questions.length, equals(25));

      final q1 = topic.questions.first;
      expect(q1.correctOption, equals('A'));
      expect(q1.explanation.wrong.containsKey('B'), isTrue);
      expect(q1.explanation.wrong.containsKey('C'), isTrue);
    });

    test('SRS schedule adheres strictly to [1, 2, 4, 8, 12] days', () {
      final initial = SrsProgressModel(
        id: 'srs_test_1',
        userId: 'user_1',
        topicId: 'grammar_purpose_001',
        questionId: 1,
        jlpt: 'N3',
        stage: 1,
        nextReviewDate: DateTime.now(),
        lastReviewedDate: DateTime.now(),
      );

      // Stage 1 corresponds to interval of 1 day
      expect(initial.intervalDays, equals(1));

      // Correct answer moves to stage 2 -> 2 days
      final stage2 = initial.copyWithResult(isCorrect: true);
      expect(stage2.stage, equals(2));
      expect(stage2.intervalDays, equals(2));

      // Correct answer moves to stage 3 -> 4 days
      final stage3 = stage2.copyWithResult(isCorrect: true);
      expect(stage3.stage, equals(3));
      expect(stage3.intervalDays, equals(4));

      // Correct answer moves to stage 4 -> 8 days
      final stage4 = stage3.copyWithResult(isCorrect: true);
      expect(stage4.stage, equals(4));
      expect(stage4.intervalDays, equals(8));

      // Correct answer moves to stage 5 -> 12 days
      final stage5 = stage4.copyWithResult(isCorrect: true);
      expect(stage5.stage, equals(5));
      expect(stage5.intervalDays, equals(12));

      // Incorrect answer demotes back to stage 1 (1-day review in Spaced Repetition) & marks difficult
      final failed = stage5.copyWithResult(isCorrect: false);
      expect(failed.stage, equals(1));
      expect(failed.wrongCount, equals(1));
      expect(failed.isDifficult, isTrue);
    });

    test('10+ correct tests graduate question to Easy Word / Mastered Grammar', () {
      var progress = SrsProgressModel(
        id: 'srs_test_easy',
        userId: 'user_1',
        topicId: 'grammar_purpose_001',
        questionId: 1,
        jlpt: 'N3',
        stage: 1,
        nextReviewDate: DateTime.now(),
        lastReviewedDate: DateTime.now(),
      );

      expect(progress.isEasy, isFalse);

      for (int i = 0; i < 9; i++) {
        progress = progress.copyWithResult(isCorrect: true);
      }
      expect(progress.correctCount, equals(9));
      expect(progress.isEasy, isFalse);

      // 10th correct test marks it as Easy / Mastered
      progress = progress.copyWithResult(isCorrect: true);
      expect(progress.correctCount, equals(10));
      expect(progress.isEasy, isTrue);
    });

    test('Initial sample topics contain all 5 JLPT levels (N5..N1)', () {
      final topics = SampleGrammarData.getInitialSampleGrammarTopics();
      final levels = topics.map((t) => t.jlpt).toSet();
      expect(levels.contains('N5'), isTrue);
      expect(levels.contains('N4'), isTrue);
      expect(levels.contains('N3'), isTrue);
      expect(levels.contains('N2'), isTrue);
      expect(levels.contains('N1'), isTrue);
    });
  });
}
