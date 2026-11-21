import 'dart:convert';

class QuestionExplanation {
  final String correct;
  final Map<String, String> wrong;

  QuestionExplanation({
    required this.correct,
    required this.wrong,
  });

  factory QuestionExplanation.fromMap(dynamic map) {
    if (map is! Map) {
      return QuestionExplanation(correct: map?.toString() ?? '', wrong: {});
    }
    final wrongMap = <String, String>{};
    if (map['wrong'] is Map) {
      (map['wrong'] as Map).forEach((k, v) {
        wrongMap[k.toString()] = v?.toString() ?? '';
      });
    }
    return QuestionExplanation(
      correct: map['correct']?.toString() ?? '',
      wrong: wrongMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'correct': correct,
      'wrong': wrong,
    };
  }
}

class VocabularyQuestion {
  final dynamic id;
  final String type; // meaning, sentenceCompletion, correctUsage, incorrectUsage, collocation, contextInference
  final String japanese;
  final String english;
  final String question;
  final Map<String, String> options;
  final String correctOption;
  final String completedSentence;
  final QuestionExplanation explanation;

  VocabularyQuestion({
    required this.id,
    required this.type,
    this.japanese = '',
    this.english = '',
    this.question = '',
    required this.options,
    required this.correctOption,
    this.completedSentence = '',
    required this.explanation,
  });

  factory VocabularyQuestion.fromMap(Map<String, dynamic> map) {
    final opts = <String, String>{};
    final rawOptions = map['options'] ?? map['choices'] ?? map['answers'];
    if (rawOptions is Map) {
      rawOptions.forEach((k, v) {
        opts[k.toString()] = v?.toString() ?? '';
      });
    } else if (rawOptions is List) {
      final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
      for (int i = 0; i < rawOptions.length; i++) {
        final key = i < labels.length ? labels[i] : (i + 1).toString();
        opts[key] = rawOptions[i]?.toString() ?? '';
      }
    }

    final rawCorrect = map['correctOption'] ??
        map['correct_option'] ??
        map['correct'] ??
        map['answer'] ??
        map['correctAnswer'];

    String resolvedCorrect = '';
    if (rawCorrect is int) {
      const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
      if (rawCorrect >= 0 && rawCorrect < labels.length) {
        resolvedCorrect = labels[rawCorrect];
      } else {
        resolvedCorrect = rawCorrect.toString();
      }
    } else if (rawCorrect != null) {
      final str = rawCorrect.toString().trim();
      if (str == '0') {
        resolvedCorrect = 'A';
      } else if (str == '1' && !opts.containsKey('1') && opts.containsKey('A')) {
        resolvedCorrect = 'A';
      } else if (str == '2' && !opts.containsKey('2') && opts.containsKey('B')) {
        resolvedCorrect = 'B';
      } else if (str == '3' && !opts.containsKey('3') && opts.containsKey('C')) {
        resolvedCorrect = 'C';
      } else if (str == '4' && !opts.containsKey('4') && opts.containsKey('D')) {
        resolvedCorrect = 'D';
      } else if (!opts.containsKey(str)) {
        for (final entry in opts.entries) {
          if (entry.value.trim() == str) {
            resolvedCorrect = entry.key;
            break;
          }
        }
        if (resolvedCorrect.isEmpty) resolvedCorrect = str;
      } else {
        resolvedCorrect = str;
      }
    }

    final rawExp = map['explanation'] ?? map['explanation_text'] ?? map['detail'] ?? map['reason'];

    return VocabularyQuestion(
      id: map['id'] ?? 0,
      type: map['type']?.toString() ?? 'meaning',
      japanese: map['japanese']?.toString() ?? map['sentence']?.toString() ?? map['jp']?.toString() ?? '',
      english: map['english']?.toString() ?? map['translation']?.toString() ?? map['meaning']?.toString() ?? map['en']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      options: opts,
      correctOption: resolvedCorrect.isNotEmpty ? resolvedCorrect : 'A',
      completedSentence: map['completedSentence']?.toString() ?? map['completed_sentence']?.toString() ?? map['fullSentence']?.toString() ?? '',
      explanation: QuestionExplanation.fromMap(rawExp),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'japanese': japanese,
      'english': english,
      'question': question,
      'options': options,
      'correctOption': correctOption,
      'completedSentence': completedSentence,
      'explanation': explanation.toMap(),
    };
  }
}

class VocabularyItem {
  final String id;
  final String word;
  final String reading;
  final String meaning;
  final String partOfSpeech;
  final String explanation;
  final List<String> commonCollocations;
  final List<VocabularyQuestion> questions;

  VocabularyItem({
    required this.id,
    required this.word,
    required this.reading,
    required this.meaning,
    this.partOfSpeech = '',
    this.explanation = '',
    this.commonCollocations = const [],
    this.questions = const [],
  });

  factory VocabularyItem.fromMap(Map<String, dynamic> map) {
    final collocations = <String>[];
    if (map['commonCollocations'] is List) {
      for (final c in map['commonCollocations']) {
        collocations.add(c.toString());
      }
    }

    final questionsList = <VocabularyQuestion>[];
    if (map['questions'] is List) {
      for (final q in map['questions']) {
        if (q is Map<String, dynamic>) {
          questionsList.add(VocabularyQuestion.fromMap(q));
        } else if (q is Map) {
          questionsList.add(VocabularyQuestion.fromMap(Map<String, dynamic>.from(q)));
        }
      }
    }

    return VocabularyItem(
      id: map['id']?.toString() ?? '',
      word: map['word']?.toString() ?? '',
      reading: map['reading']?.toString() ?? '',
      meaning: map['meaning']?.toString() ?? '',
      partOfSpeech: map['partOfSpeech']?.toString() ?? '',
      explanation: map['explanation']?.toString() ?? '',
      commonCollocations: collocations,
      questions: questionsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'reading': reading,
      'meaning': meaning,
      'partOfSpeech': partOfSpeech,
      'explanation': explanation,
      'commonCollocations': commonCollocations,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}

class VocabularyTopicModel {
  final String id;
  final String title;
  final String jlpt;
  final String section;
  final List<String> tags;
  final List<VocabularyItem> vocabulary;
  final Map<String, dynamic> metadata;

  VocabularyTopicModel({
    required this.id,
    required this.title,
    required this.jlpt,
    this.section = 'Vocabulary',
    this.tags = const [],
    required this.vocabulary,
    this.metadata = const {},
  });

  factory VocabularyTopicModel.fromMap(Map<String, dynamic> map) {
    final tagsList = <String>[];
    if (map['tags'] is List) {
      for (final t in map['tags']) {
        tagsList.add(t.toString());
      }
    }

    final vocabList = <VocabularyItem>[];
    if (map['vocabulary'] is List) {
      for (final v in map['vocabulary']) {
        if (v is Map<String, dynamic>) {
          vocabList.add(VocabularyItem.fromMap(v));
        } else if (v is Map) {
          vocabList.add(VocabularyItem.fromMap(Map<String, dynamic>.from(v)));
        }
      }
    }

    return VocabularyTopicModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      jlpt: map['jlpt']?.toString() ?? 'N2',
      section: map['section']?.toString() ?? 'Vocabulary',
      tags: tagsList,
      vocabulary: vocabList,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
    );
  }

  factory VocabularyTopicModel.fromJson(String source) =>
      VocabularyTopicModel.fromMap(json.decode(source));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'jlpt': jlpt,
      'section': section,
      'tags': tags,
      'vocabulary': vocabulary.map((v) => v.toMap()).toList(),
      'metadata': metadata,
    };
  }

  String toJson() => json.encode(toMap());
}

