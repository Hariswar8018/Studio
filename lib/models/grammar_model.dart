import 'dart:convert';

class GrammarPointItem {
  final String id;
  final String grammar;
  final String meaning;
  final String structure;
  final String explanation;

  GrammarPointItem({
    required this.id,
    required this.grammar,
    required this.meaning,
    required this.structure,
    required this.explanation,
  });

  factory GrammarPointItem.fromMap(Map<String, dynamic> map) {
    return GrammarPointItem(
      id: map['id']?.toString() ?? '',
      grammar: map['grammar']?.toString() ??
          map['grammarPoint']?.toString() ??
          map['grammar_point']?.toString() ??
          map['point']?.toString() ??
          map['pattern']?.toString() ??
          map['japanese']?.toString() ??
          map['expression']?.toString() ??
          map['title']?.toString() ??
          map['name']?.toString() ??
          map['text']?.toString() ??
          '',
      meaning: map['meaning']?.toString() ??
          map['english']?.toString() ??
          map['translation']?.toString() ??
          map['definition']?.toString() ??
          map['desc']?.toString() ??
          '',
      structure: map['structure']?.toString() ??
          map['formation']?.toString() ??
          map['form']?.toString() ??
          map['syntax']?.toString() ??
          map['connection']?.toString() ??
          map['rule']?.toString() ??
          map['construction']?.toString() ??
          '',
      explanation: map['explanation']?.toString() ??
          map['usage']?.toString() ??
          map['nuance']?.toString() ??
          map['notes']?.toString() ??
          map['description']?.toString() ??
          map['detail']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grammar': grammar,
      'meaning': meaning,
      'structure': structure,
      'explanation': explanation,
    };
  }
}

class GlobalGrammarOption {
  final String grammar;
  final String meaning;
  final String structure;
  final String usage;

  GlobalGrammarOption({
    required this.grammar,
    this.meaning = '',
    this.structure = '',
    this.usage = '',
  });

  factory GlobalGrammarOption.fromMap(dynamic val, [String? keyName]) {
    if (val is String) {
      return GlobalGrammarOption(
        grammar: val,
        meaning: '',
        structure: '',
        usage: '',
      );
    }
    if (val is Map) {
      String grammar = val['grammar']?.toString() ??
          val['grammarPoint']?.toString() ??
          val['grammar_point']?.toString() ??
          val['point']?.toString() ??
          val['pattern']?.toString() ??
          val['japanese']?.toString() ??
          val['expression']?.toString() ??
          val['title']?.toString() ??
          val['name']?.toString() ??
          val['form']?.toString() ??
          val['label']?.toString() ??
          val['text']?.toString() ??
          val['word']?.toString() ??
          val['item']?.toString() ??
          val['kanji']?.toString() ??
          '';

      String meaning = val['meaning']?.toString() ??
          val['english']?.toString() ??
          val['translation']?.toString() ??
          val['definition']?.toString() ??
          val['desc']?.toString() ??
          '';

      String structure = val['structure']?.toString() ??
          val['formation']?.toString() ??
          val['form']?.toString() ??
          val['syntax']?.toString() ??
          val['connection']?.toString() ??
          val['rule']?.toString() ??
          val['construction']?.toString() ??
          val['formula']?.toString() ??
          '';

      String usage = val['usage']?.toString() ??
          val['nuance']?.toString() ??
          val['usageAndNuance']?.toString() ??
          val['usage_nuance']?.toString() ??
          val['explanation']?.toString() ??
          val['description']?.toString() ??
          val['notes']?.toString() ??
          val['note']?.toString() ??
          val['detail']?.toString() ??
          val['details']?.toString() ??
          val['example']?.toString() ??
          '';

      // If grammar is empty, check any key with Japanese text
      if (grammar.isEmpty) {
        for (final entry in val.entries) {
          final k = entry.key.toString().toLowerCase();
          final v = entry.value?.toString().trim() ?? '';
          if (k != 'meaning' &&
              k != 'english' &&
              k != 'translation' &&
              k != 'definition' &&
              k != 'structure' &&
              k != 'formation' &&
              k != 'usage' &&
              k != 'nuance' &&
              k != 'explanation') {
            if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(v)) {
              grammar = v;
              break;
            }
          }
        }
      }

      // If grammar is still empty and keyName contains Japanese
      if (grammar.isEmpty &&
          keyName != null &&
          RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(keyName)) {
        grammar = keyName;
      }

      return GlobalGrammarOption(
        grammar: grammar,
        meaning: meaning,
        structure: structure,
        usage: usage,
      );
    }
    return GlobalGrammarOption(grammar: val?.toString() ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'grammar': grammar,
      'meaning': meaning,
      'structure': structure,
      'usage': usage,
    };
  }
}

class GrammarExplanation {
  final String correct;
  final Map<String, String> wrong;
  final String? grammarPoint;

  GrammarExplanation({
    required this.correct,
    required this.wrong,
    this.grammarPoint,
  });

  factory GrammarExplanation.fromMap(dynamic val) {
    if (val == null) {
      return GrammarExplanation(correct: '', wrong: {});
    }
    if (val is String) {
      return GrammarExplanation(correct: val, wrong: {});
    }
    if (val is Map) {
      final wrongMap = <String, String>{};
      final rawWrong = val['wrong'] ?? val['incorrect'] ?? val['distractors'];
      if (rawWrong is Map) {
        rawWrong.forEach((key, value) {
          wrongMap[key.toString()] = value?.toString() ?? '';
        });
      } else if (rawWrong is List) {
        final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
        for (int i = 0; i < rawWrong.length; i++) {
          final k = i < labels.length ? labels[i] : (i + 1).toString();
          wrongMap[k] = rawWrong[i]?.toString() ?? '';
        }
      }

      final correctText = val['correct']?.toString() ??
          val['explanation']?.toString() ??
          val['text']?.toString() ??
          val['detail']?.toString() ??
          val['reason']?.toString() ??
          '';

      final gpText = val['grammarPoint']?.toString() ??
          val['grammar_point']?.toString() ??
          val['grammar']?.toString();

      return GrammarExplanation(
        correct: correctText,
        wrong: wrongMap,
        grammarPoint: gpText,
      );
    }
    return GrammarExplanation(correct: val.toString(), wrong: {});
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'correct': correct,
      'wrong': wrong,
    };
    if (grammarPoint != null && grammarPoint!.isNotEmpty) {
      map['grammarPoint'] = grammarPoint;
    }
    return map;
  }
}

class GrammarQuestion {
  final int id;
  final String type; // 'globalGrammar', 'localVocabulary', etc.
  final String grammarId; // e.g. 'wo_towazu', 'ni_kakawarazu'
  final GrammarPointItem? grammarPoint; // optional explicit grammar point item
  final String japanese;
  final String english;
  final Map<String, String>? options; // Local options: {"A": "学歴", ...}
  final String correctOption;
  final String completedSentence;
  final GrammarExplanation explanation;
  final bool needsRevision;

  GrammarQuestion({
    required this.id,
    this.type = 'globalGrammar',
    this.grammarId = '',
    this.grammarPoint,
    required this.japanese,
    required this.english,
    this.options,
    required this.correctOption,
    required this.completedSentence,
    required this.explanation,
    this.needsRevision = false,
  });

  /// Returns true if this question defines its own localized options with actual text
  bool get hasLocalOptions =>
      options != null &&
      options!.isNotEmpty &&
      options!.values.any((v) => v.trim().isNotEmpty);

  /// Helper to get options for this question given the topic's globalOptions
  Map<String, String> getEffectiveOptions(Map<String, GlobalGrammarOption> globalOptions) {
    if (hasLocalOptions) {
      return options!;
    }
    if (globalOptions.isNotEmpty) {
      final map = <String, String>{};
      globalOptions.forEach((k, v) {
        String label = v.grammar.trim();
        if (label.isEmpty) {
          label = v.meaning.trim();
        }
        if (label.isEmpty) {
          label = 'Option $k';
        }
        map[k] = label;
      });
      return map;
    }
    if (options != null && options!.isNotEmpty) {
      return options!;
    }
    return {};
  }

  factory GrammarQuestion.fromMap(Map<String, dynamic> map) {
    // 1. Local options from 'options', 'choices', or 'answers'
    Map<String, String>? localOpts;
    final rawOptions = map['options'] ?? map['choices'] ?? map['answers'];
    if (rawOptions is Map) {
      localOpts = {};
      rawOptions.forEach((k, v) {
        localOpts![k.toString()] = v?.toString() ?? '';
      });
    } else if (rawOptions is List) {
      localOpts = {};
      final labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      for (int i = 0; i < rawOptions.length; i++) {
        final key = i < labels.length ? labels[i] : (i + 1).toString();
        localOpts[key] = rawOptions[i]?.toString() ?? '';
      }
    }

    // 2. Correct option resolver
    final rawCorrect = map['correctOption'] ??
        map['correct_option'] ??
        map['correct'] ??
        map['answer'] ??
        map['correctAnswer'];

    String resolvedCorrect = '';
    if (rawCorrect is int) {
      const labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      if (rawCorrect >= 0 && rawCorrect < labels.length) {
        resolvedCorrect = labels[rawCorrect];
      } else {
        resolvedCorrect = rawCorrect.toString();
      }
    } else if (rawCorrect != null) {
      final str = rawCorrect.toString().trim();
      // If correctOption is a 0-based or 1-based digit string
      if (str == '0') {
        resolvedCorrect = 'A';
      } else if (str == '1' && (localOpts != null && !localOpts.containsKey('1') && localOpts.containsKey('A'))) {
        resolvedCorrect = 'A';
      } else if (str == '2' && (localOpts != null && !localOpts.containsKey('2') && localOpts.containsKey('B'))) {
        resolvedCorrect = 'B';
      } else if (str == '3' && (localOpts != null && !localOpts.containsKey('3') && localOpts.containsKey('C'))) {
        resolvedCorrect = 'C';
      } else if (str == '4' && (localOpts != null && !localOpts.containsKey('4') && localOpts.containsKey('D'))) {
        resolvedCorrect = 'D';
      } else if (localOpts != null && !localOpts.containsKey(str)) {
        // Check if rawCorrect matches any option value text
        for (final entry in localOpts.entries) {
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

    // 3. Grammar point item if present in question
    GrammarPointItem? gpItem;
    final rawGp = map['grammarPoint'] ?? map['grammar_point'] ?? map['point'];
    if (rawGp is Map) {
      gpItem = GrammarPointItem.fromMap(Map<String, dynamic>.from(rawGp));
    } else if (rawGp is String && rawGp.isNotEmpty) {
      gpItem = GrammarPointItem(
        id: map['grammarId']?.toString() ?? '',
        grammar: rawGp,
        meaning: '',
        structure: '',
        explanation: '',
      );
    }

    final rawExplanation = map['explanation'] ??
        map['explanation_text'] ??
        map['detail'] ??
        map['reason'] ??
        map['analysis'];

    return GrammarQuestion(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      type: map['type']?.toString() ?? (localOpts != null && localOpts.isNotEmpty ? 'localVocabulary' : 'globalGrammar'),
      grammarId: map['grammarId']?.toString() ?? map['grammar_id']?.toString() ?? map['grammar']?.toString() ?? '',
      grammarPoint: gpItem,
      japanese: map['japanese']?.toString() ?? map['sentence']?.toString() ?? map['question']?.toString() ?? map['jp']?.toString() ?? '',
      english: map['english']?.toString() ?? map['translation']?.toString() ?? map['meaning']?.toString() ?? map['en']?.toString() ?? '',
      options: localOpts,
      correctOption: resolvedCorrect.isNotEmpty ? resolvedCorrect : 'A',
      completedSentence: map['completedSentence']?.toString() ?? map['completed_sentence']?.toString() ?? map['fullSentence']?.toString() ?? '',
      explanation: GrammarExplanation.fromMap(rawExplanation),
      needsRevision: map['needsRevision'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    final res = <String, dynamic>{
      'id': id,
      'type': type,
      'grammarId': grammarId,
      'japanese': japanese,
      'english': english,
      'correctOption': correctOption,
      'completedSentence': completedSentence,
      'explanation': explanation.toMap(),
      'needsRevision': needsRevision,
    };
    if (grammarPoint != null) {
      res['grammarPoint'] = grammarPoint!.toMap();
    }
    if (options != null) {
      res['options'] = options;
    }
    return res;
  }
}

class GrammarMetadata {
  final int totalQuestions;
  final List<String> questionTypes;
  final int version;

  GrammarMetadata({
    this.totalQuestions = 0,
    this.questionTypes = const ['globalGrammar', 'localVocabulary'],
    this.version = 2,
  });

  factory GrammarMetadata.fromMap(Map<String, dynamic> map) {
    final types = (map['questionTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        (map['questionType'] != null ? [map['questionType'].toString()] : <String>['globalGrammar']);

    return GrammarMetadata(
      totalQuestions: map['totalQuestions'] is int
          ? map['totalQuestions']
          : (map['questionCount'] is int
              ? map['questionCount']
              : int.tryParse(map['totalQuestions']?.toString() ?? map['questionCount']?.toString() ?? '0') ?? 0),
      questionTypes: types,
      version: map['version'] is int ? map['version'] : int.tryParse(map['version']?.toString() ?? '2') ?? 2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalQuestions': totalQuestions,
      'questionTypes': questionTypes,
      'version': version,
    };
  }
}

class GrammarTopicModel {
  final String id;
  final String title;
  final String jlpt; // 'N5', 'N4', 'N3', 'N2', 'N1'
  final String section;
  final String category;
  final List<String> tags;
  final String description;
  final List<GrammarPointItem> grammarPoints;
  final Map<String, GlobalGrammarOption> globalOptions;
  final String instructions;
  final List<GrammarQuestion> questions;
  final GrammarMetadata metadata;

  GrammarTopicModel({
    required this.id,
    required this.title,
    required this.jlpt,
    this.section = 'Grammar',
    required this.category,
    required this.tags,
    required this.description,
    this.grammarPoints = const [],
    required this.globalOptions,
    required this.instructions,
    required this.questions,
    required this.metadata,
  });

  factory GrammarTopicModel.fromMap(Map<String, dynamic> map) {
    // 1. Parse grammarPoints if present
    final pointsList = <GrammarPointItem>[];
    final rawPoints = map['grammarPoints'] ??
        map['grammar_points'] ??
        map['points'] ??
        map['patterns'] ??
        map['grammar_patterns'] ??
        map['items'];
    if (rawPoints is List) {
      for (var p in rawPoints) {
        if (p is Map) {
          pointsList.add(GrammarPointItem.fromMap(Map<String, dynamic>.from(p)));
        }
      }
    }

    // 2. Parse globalOptions (supports Map or List, under globalOptions, options, global_options, etc.)
    final optionsMap = <String, GlobalGrammarOption>{};
    final rawGlobal = map['globalOptions'] ??
        map['options'] ??
        map['global_options'] ??
        map['grammar_options'] ??
        map['choices'];
    if (rawGlobal is Map) {
      rawGlobal.forEach((k, v) {
        optionsMap[k.toString()] = GlobalGrammarOption.fromMap(v, k.toString());
      });
    } else if (rawGlobal is List) {
      final labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      for (int i = 0; i < rawGlobal.length; i++) {
        final key = i < labels.length ? labels[i] : (i + 1).toString();
        optionsMap[key] = GlobalGrammarOption.fromMap(rawGlobal[i], key);
      }
    }

    // 3. Parse questions
    final questionsList = <GrammarQuestion>[];
    final rawQuestions = map['questions'] ?? map['exercises'] ?? map['quiz'] ?? map['practice'];
    if (rawQuestions is List) {
      for (var q in rawQuestions) {
        if (q is Map) {
          questionsList.add(GrammarQuestion.fromMap(Map<String, dynamic>.from(q)));
        }
      }
    }

    // If globalOptions is empty but grammarPoints exist, synthesize globalOptions
    final labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    if (optionsMap.isEmpty && pointsList.isNotEmpty) {
      for (int i = 0; i < pointsList.length; i++) {
        final key = i < labels.length ? labels[i] : (i + 1).toString();
        final pt = pointsList[i];
        optionsMap[key] = GlobalGrammarOption(
          grammar: pt.grammar,
          meaning: pt.meaning,
          structure: pt.structure,
          usage: pt.explanation,
        );
      }
    }

    // If optionsMap exists and pointsList is empty, synthesize pointsList from optionsMap
    if (pointsList.isEmpty && optionsMap.isNotEmpty) {
      for (final entry in optionsMap.entries) {
        pointsList.add(GrammarPointItem(
          id: entry.key,
          grammar: entry.value.grammar,
          meaning: entry.value.meaning,
          structure: entry.value.structure,
          explanation: entry.value.usage,
        ));
      }
    }

    // Reconcile and enrich optionsMap
    for (final entry in optionsMap.entries) {
      final key = entry.key;
      var opt = entry.value;
      var grammar = opt.grammar;
      var meaning = opt.meaning;
      var structure = opt.structure;
      var usage = opt.usage;

      // 1. Try matching from pointsList
      if (grammar.isEmpty || structure.isEmpty || usage.isEmpty) {
        for (final pt in pointsList) {
          if (meaning.isNotEmpty &&
              pt.meaning.isNotEmpty &&
              (meaning.toLowerCase() == pt.meaning.toLowerCase() ||
                  pt.meaning.toLowerCase().contains(meaning.toLowerCase()) ||
                  meaning.toLowerCase().contains(pt.meaning.toLowerCase()))) {
            if (grammar.isEmpty) grammar = pt.grammar;
            if (structure.isEmpty) structure = pt.structure;
            if (usage.isEmpty) usage = pt.explanation;
            break;
          }
        }
        if (grammar.isEmpty) {
          final idx = labels.indexOf(key.toUpperCase());
          if (idx >= 0 && idx < pointsList.length) {
            final pt = pointsList[idx];
            if (grammar.isEmpty) grammar = pt.grammar;
            if (meaning.isEmpty) meaning = pt.meaning;
            if (structure.isEmpty) structure = pt.structure;
            if (usage.isEmpty) usage = pt.explanation;
          }
        }
      }

      // 2. Try inferring grammar from questions if still empty
      if (grammar.isEmpty) {
        for (final q in questionsList) {
          if (q.correctOption == key) {
            if (q.explanation.grammarPoint != null && q.explanation.grammarPoint!.isNotEmpty) {
              grammar = q.explanation.grammarPoint!;
              break;
            }
            if (q.grammarId.isNotEmpty &&
                RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(q.grammarId)) {
              grammar = q.grammarId;
              break;
            }
            if (q.completedSentence.isNotEmpty && q.japanese.contains('___')) {
              final parts = q.japanese.split('___');
              if (parts.length == 2) {
                final prefix = parts[0];
                final suffix = parts[1];
                var sentence = q.completedSentence;
                if (prefix.isNotEmpty && sentence.startsWith(prefix)) {
                  sentence = sentence.substring(prefix.length);
                }
                if (suffix.isNotEmpty && sentence.endsWith(suffix)) {
                  sentence = sentence.substring(0, sentence.length - suffix.length);
                }
                if (sentence.isNotEmpty && sentence.length < 25) {
                  grammar = sentence.trim();
                  break;
                }
              }
            }
          }
        }
      }

      optionsMap[key] = GlobalGrammarOption(
        grammar: grammar,
        meaning: meaning,
        structure: structure,
        usage: usage,
      );
    }

    // Keep pointsList in sync
    for (int i = 0; i < pointsList.length; i++) {
      final pt = pointsList[i];
      final key = i < labels.length ? labels[i] : (i + 1).toString();
      final opt = optionsMap[key];
      if (opt != null) {
        pointsList[i] = GrammarPointItem(
          id: pt.id.isNotEmpty ? pt.id : key,
          grammar: pt.grammar.isNotEmpty ? pt.grammar : opt.grammar,
          meaning: pt.meaning.isNotEmpty ? pt.meaning : opt.meaning,
          structure: pt.structure.isNotEmpty ? pt.structure : opt.structure,
          explanation: pt.explanation.isNotEmpty ? pt.explanation : opt.usage,
        );
      }
    }

    final tagsList = (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return GrammarTopicModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      jlpt: (map['jlpt']?.toString() ?? 'N3').toUpperCase(),
      section: map['section']?.toString() ?? 'Grammar',
      category: map['category']?.toString() ?? map['section']?.toString() ?? 'General Grammar',
      tags: tagsList,
      description: map['description']?.toString() ?? '',
      grammarPoints: pointsList,
      globalOptions: optionsMap,
      instructions: map['instructions']?.toString() ?? '',
      questions: questionsList,
      metadata: GrammarMetadata.fromMap(
        map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'jlpt': jlpt,
      'section': section,
      'category': category,
      'tags': tags,
      'description': description,
      'globalOptions': globalOptions.map((k, v) => MapEntry(k, v.toMap())),
      'instructions': instructions,
      'questions': questions.map((q) => q.toMap()).toList(),
      'metadata': metadata.toMap(),
    };
    if (grammarPoints.isNotEmpty) {
      map['grammarPoints'] = grammarPoints.map((p) => p.toMap()).toList();
    }
    return map;
  }

  String toJsonString() => json.encode(toMap());

  factory GrammarTopicModel.fromJson(Map<String, dynamic> json) =>
      GrammarTopicModel.fromMap(json);

  factory GrammarTopicModel.fromJsonString(String source) =>
      GrammarTopicModel.fromMap(json.decode(source));
}
