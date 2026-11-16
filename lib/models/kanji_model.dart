import 'dart:convert';
import 'vocab_model.dart';

class KanjiCommonWord {
  final String word;
  final String reading;
  final String meaning;

  KanjiCommonWord({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  factory KanjiCommonWord.fromMap(Map<String, dynamic> map) {
    return KanjiCommonWord(
      word: map['word']?.toString() ?? '',
      reading: map['reading']?.toString() ?? '',
      meaning: map['meaning']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'reading': reading,
      'meaning': meaning,
    };
  }
}

class KanjiQuestion {
  final dynamic id;
  final String type; // kanjiReading, kanjiSelection, kanjiMeaning, similarKanji, compoundWord, contextUsage
  final String japanese;
  final String english;
  final String question;
  final Map<String, String> options;
  final String correctOption;
  final String completedSentence;
  final QuestionExplanation explanation;

  KanjiQuestion({
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

  factory KanjiQuestion.fromMap(Map<String, dynamic> map) {
    final opts = <String, String>{};
    if (map['options'] is Map) {
      (map['options'] as Map).forEach((k, v) {
        opts[k.toString()] = v?.toString() ?? '';
      });
    }

    return KanjiQuestion(
      id: map['id'] ?? 0,
      type: map['type']?.toString() ?? 'kanjiReading',
      japanese: map['japanese']?.toString() ?? '',
      english: map['english']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      options: opts,
      correctOption: map['correctOption']?.toString() ?? 'A',
      completedSentence: map['completedSentence']?.toString() ?? '',
      explanation: QuestionExplanation.fromMap(map['explanation']),
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

class KanjiItem {
  final String id;
  final String character;
  final List<String> onyomi;
  final List<String> kunyomi;
  final List<String> meanings;
  final int strokeCount;
  final String explanation;
  final List<KanjiCommonWord> commonWords;
  final List<KanjiQuestion> questions;

  KanjiItem({
    required this.id,
    required this.character,
    this.onyomi = const [],
    this.kunyomi = const [],
    this.meanings = const [],
    this.strokeCount = 1,
    this.explanation = '',
    this.commonWords = const [],
    this.questions = const [],
  });

  factory KanjiItem.fromMap(Map<String, dynamic> map) {
    final on = <String>[];
    if (map['onyomi'] is List) {
      for (final o in map['onyomi']) {
        on.add(o.toString());
      }
    }

    final kun = <String>[];
    if (map['kunyomi'] is List) {
      for (final k in map['kunyomi']) {
        kun.add(k.toString());
      }
    }

    final mList = <String>[];
    if (map['meanings'] is List) {
      for (final m in map['meanings']) {
        mList.add(m.toString());
      }
    }

    final words = <KanjiCommonWord>[];
    if (map['commonWords'] is List) {
      for (final w in map['commonWords']) {
        if (w is Map<String, dynamic>) {
          words.add(KanjiCommonWord.fromMap(w));
        } else if (w is Map) {
          words.add(KanjiCommonWord.fromMap(Map<String, dynamic>.from(w)));
        }
      }
    }

    final questionsList = <KanjiQuestion>[];
    if (map['questions'] is List) {
      for (final q in map['questions']) {
        if (q is Map<String, dynamic>) {
          questionsList.add(KanjiQuestion.fromMap(q));
        } else if (q is Map) {
          questionsList.add(KanjiQuestion.fromMap(Map<String, dynamic>.from(q)));
        }
      }
    }

    return KanjiItem(
      id: map['id']?.toString() ?? '',
      character: map['character']?.toString() ?? '',
      onyomi: on,
      kunyomi: kun,
      meanings: mList,
      strokeCount: int.tryParse(map['strokeCount']?.toString() ?? '1') ?? 1,
      explanation: map['explanation']?.toString() ?? '',
      commonWords: words,
      questions: questionsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character': character,
      'onyomi': onyomi,
      'kunyomi': kunyomi,
      'meanings': meanings,
      'strokeCount': strokeCount,
      'explanation': explanation,
      'commonWords': commonWords.map((w) => w.toMap()).toList(),
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}

class KanjiTopicModel {
  final String id;
  final String title;
  final String jlpt;
  final String section;
  final List<String> tags;
  final List<KanjiItem> kanji;
  final Map<String, dynamic> metadata;

  KanjiTopicModel({
    required this.id,
    required this.title,
    required this.jlpt,
    this.section = 'Kanji',
    this.tags = const [],
    required this.kanji,
    this.metadata = const {},
  });

  factory KanjiTopicModel.fromMap(Map<String, dynamic> map) {
    final tagsList = <String>[];
    if (map['tags'] is List) {
      for (final t in map['tags']) {
        tagsList.add(t.toString());
      }
    }

    final kanjiList = <KanjiItem>[];
    if (map['kanji'] is List) {
      for (final k in map['kanji']) {
        if (k is Map<String, dynamic>) {
          kanjiList.add(KanjiItem.fromMap(k));
        } else if (k is Map) {
          kanjiList.add(KanjiItem.fromMap(Map<String, dynamic>.from(k)));
        }
      }
    }

    return KanjiTopicModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      jlpt: map['jlpt']?.toString() ?? 'N2',
      section: map['section']?.toString() ?? 'Kanji',
      tags: tagsList,
      kanji: kanjiList,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
    );
  }

  factory KanjiTopicModel.fromJson(String source) =>
      KanjiTopicModel.fromMap(json.decode(source));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'jlpt': jlpt,
      'section': section,
      'tags': tags,
      'kanji': kanji.map((k) => k.toMap()).toList(),
      'metadata': metadata,
    };
  }

  String toJson() => json.encode(toMap());
}

