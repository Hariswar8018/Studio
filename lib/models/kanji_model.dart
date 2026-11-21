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

    return KanjiQuestion(
      id: map['id'] ?? 0,
      type: map['type']?.toString() ?? 'kanjiReading',
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
    String char = map['character']?.toString() ??
        map['word']?.toString() ??
        map['kanji']?.toString() ??
        map['char']?.toString() ??
        map['item']?.toString() ??
        map['name']?.toString() ??
        '';
    if (char.isEmpty && map['kanjiCharacters'] is List && (map['kanjiCharacters'] as List).isNotEmpty) {
      char = (map['kanjiCharacters'] as List).join('');
    }

    final on = <String>[];
    if (map['onyomi'] is List) {
      for (final o in map['onyomi']) {
        on.add(o.toString());
      }
    } else if (map['onyomi'] is String && map['onyomi'].toString().isNotEmpty) {
      for (final o in map['onyomi'].toString().split(RegExp(r'[,、]'))) {
        if (o.trim().isNotEmpty) on.add(o.trim());
      }
    }

    final kun = <String>[];
    if (map['kunyomi'] is List) {
      for (final k in map['kunyomi']) {
        kun.add(k.toString());
      }
    } else if (map['kunyomi'] is String && map['kunyomi'].toString().isNotEmpty) {
      for (final k in map['kunyomi'].toString().split(RegExp(r'[,、]'))) {
        if (k.trim().isNotEmpty) kun.add(k.trim());
      }
    }

    // If on and kun are empty, check 'reading' or 'kana' or 'readings'
    if (on.isEmpty && kun.isEmpty) {
      final rawReading = map['reading']?.toString() ?? map['kana']?.toString() ?? map['readings']?.toString() ?? '';
      if (rawReading.isNotEmpty) {
        for (final r in rawReading.split(RegExp(r'[,、;/]'))) {
          final trimmed = r.trim();
          if (trimmed.isEmpty) continue;
          if (RegExp(r'[\u30A0-\u30FF]').hasMatch(trimmed)) {
            on.add(trimmed);
          } else {
            kun.add(trimmed);
          }
        }
        if (on.isEmpty && kun.isEmpty) {
          kun.add(rawReading.trim());
        }
      }
    }

    final mList = <String>[];
    if (map['meanings'] is List) {
      for (final m in map['meanings']) {
        mList.add(m.toString());
      }
    } else if (map['meaning'] != null) {
      final rawMeaning = map['meaning'].toString();
      for (final part in rawMeaning.split(RegExp(r'[;,]'))) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty && !mList.contains(trimmed)) {
          mList.add(trimmed);
        }
      }
    } else if (map['english'] != null) {
      mList.add(map['english'].toString());
    } else if (map['translation'] != null) {
      mList.add(map['translation'].toString());
    }

    final words = <KanjiCommonWord>[];
    final rawWords = map['commonWords'] ?? map['compounds'] ?? map['words'] ?? map['examples'];
    if (rawWords is List) {
      for (final w in rawWords) {
        if (w is Map<String, dynamic>) {
          words.add(KanjiCommonWord.fromMap(w));
        } else if (w is Map) {
          words.add(KanjiCommonWord.fromMap(Map<String, dynamic>.from(w)));
        } else if (w is String) {
          words.add(KanjiCommonWord(word: w, reading: '', meaning: ''));
        }
      }
    }
    if (words.isEmpty && map['exampleSentence'] is Map) {
      final ex = map['exampleSentence'] as Map;
      final jp = ex['japanese']?.toString() ?? '';
      final en = ex['english']?.toString() ?? '';
      if (jp.isNotEmpty) {
        words.add(KanjiCommonWord(
          word: char.isNotEmpty ? char : jp,
          reading: kun.isNotEmpty ? kun.first : (on.isNotEmpty ? on.first : ''),
          meaning: en.isNotEmpty ? en : (mList.isNotEmpty ? mList.first : ''),
        ));
      }
    }

    String exp = map['explanation']?.toString() ?? map['notes']?.toString() ?? map['nuance']?.toString() ?? '';
    if (exp.isEmpty && map['exampleSentence'] != null) {
      final ex = map['exampleSentence'];
      if (ex is Map) {
        final jp = ex['japanese']?.toString() ?? '';
        final en = ex['english']?.toString() ?? '';
        exp = '例文: $jp${en.isNotEmpty ? ' ($en)' : ''}';
      } else if (ex is String && ex.trim().isNotEmpty) {
        exp = '例文: ${ex.trim()}';
      }
    }

    final questionsList = <KanjiQuestion>[];
    final rawQuestions = map['questions'] ?? map['quiz'] ?? map['exercises'];
    if (rawQuestions is List) {
      for (final q in rawQuestions) {
        if (q is Map<String, dynamic>) {
          questionsList.add(KanjiQuestion.fromMap(q));
        } else if (q is Map) {
          questionsList.add(KanjiQuestion.fromMap(Map<String, dynamic>.from(q)));
        }
      }
    }

    return KanjiItem(
      id: map['id']?.toString() ?? '',
      character: char,
      onyomi: on,
      kunyomi: kun,
      meanings: mList,
      strokeCount: int.tryParse(map['strokeCount']?.toString() ?? map['strokes']?.toString() ?? '1') ?? 1,
      explanation: exp,
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
    final rawKanji = map['kanji'] ?? map['items'] ?? map['characters'] ?? map['entries'] ?? map['words'] ?? map['vocabulary'];
    if (rawKanji is List) {
      for (final k in rawKanji) {
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

