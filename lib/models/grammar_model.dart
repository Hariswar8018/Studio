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
      grammar: map['grammar']?.toString() ?? '',
      meaning: map['meaning']?.toString() ?? '',
      structure: map['structure']?.toString() ?? '',
      explanation: map['explanation']?.toString() ?? '',
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

  factory GlobalGrammarOption.fromMap(dynamic val) {
    if (val is String) {
      return GlobalGrammarOption(
        grammar: val,
        meaning: '',
        structure: '',
        usage: '',
      );
    }
    if (val is Map) {
      return GlobalGrammarOption(
        grammar: val['grammar']?.toString() ?? '',
        meaning: val['meaning']?.toString() ?? '',
        structure: val['structure']?.toString() ?? '',
        usage: val['usage']?.toString() ?? val['explanation']?.toString() ?? '',
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

  GrammarExplanation({
    required this.correct,
    required this.wrong,
  });

  factory GrammarExplanation.fromMap(Map<String, dynamic> map) {
    final wrongMap = <String, String>{};
    if (map['wrong'] is Map) {
      (map['wrong'] as Map).forEach((key, value) {
        wrongMap[key.toString()] = value?.toString() ?? '';
      });
    }
    return GrammarExplanation(
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

class GrammarQuestion {
  final int id;
  final String type; // 'globalGrammar', 'localVocabulary', etc.
  final String grammarId; // e.g. 'wo_towazu', 'ni_kakawarazu'
  final String japanese;
  final String english;
  final Map<String, String>? options; // Local options (for localVocabulary questions: {"A": "学歴", ...})
  final String correctOption;
  final String completedSentence;
  final GrammarExplanation explanation;
  final bool needsRevision;

  GrammarQuestion({
    required this.id,
    this.type = 'globalGrammar',
    this.grammarId = '',
    required this.japanese,
    required this.english,
    this.options,
    required this.correctOption,
    required this.completedSentence,
    required this.explanation,
    this.needsRevision = false,
  });

  /// Returns true if this question defines its own localized options (e.g. vocabulary choices)
  bool get hasLocalOptions => options != null && options!.isNotEmpty;

  /// Helper to get options for this question given the topic's globalOptions
  Map<String, String> getEffectiveOptions(Map<String, GlobalGrammarOption> globalOptions) {
    if (hasLocalOptions) {
      return options!;
    }
    return globalOptions.map((k, v) => MapEntry(k, v.grammar));
  }

  factory GrammarQuestion.fromMap(Map<String, dynamic> map) {
    Map<String, String>? localOpts;
    if (map['options'] is Map) {
      localOpts = {};
      (map['options'] as Map).forEach((k, v) {
        localOpts![k.toString()] = v?.toString() ?? '';
      });
    }

    return GrammarQuestion(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      type: map['type']?.toString() ?? (localOpts != null ? 'localVocabulary' : 'globalGrammar'),
      grammarId: map['grammarId']?.toString() ?? '',
      japanese: map['japanese']?.toString() ?? '',
      english: map['english']?.toString() ?? '',
      options: localOpts,
      correctOption: map['correctOption']?.toString() ?? '',
      completedSentence: map['completedSentence']?.toString() ?? '',
      explanation: GrammarExplanation.fromMap(
        map['explanation'] is Map<String, dynamic>
            ? map['explanation']
            : (map['explanation'] is Map ? Map<String, dynamic>.from(map['explanation']) : {}),
      ),
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
    if (map['grammarPoints'] is List) {
      for (var p in (map['grammarPoints'] as List)) {
        if (p is Map) {
          pointsList.add(GrammarPointItem.fromMap(Map<String, dynamic>.from(p)));
        }
      }
    }

    // 2. Parse globalOptions (supports string values e.g. "A": "〜を問わず" or object values)
    final optionsMap = <String, GlobalGrammarOption>{};
    if (map['globalOptions'] is Map) {
      (map['globalOptions'] as Map).forEach((k, v) {
        optionsMap[k.toString()] = GlobalGrammarOption.fromMap(v);
      });
    }

    // If grammarPoints exist but globalOptions has empty meaning/structure, enrich it
    if (pointsList.isNotEmpty) {
      for (final pt in pointsList) {
        for (final entry in optionsMap.entries) {
          final opt = entry.value;
          if (opt.grammar == pt.grammar ||
              opt.grammar.contains(pt.grammar.replaceAll('〜', '')) ||
              pt.grammar.contains(opt.grammar.replaceAll('〜', ''))) {
            optionsMap[entry.key] = GlobalGrammarOption(
              grammar: opt.grammar,
              meaning: opt.meaning.isNotEmpty ? opt.meaning : pt.meaning,
              structure: opt.structure.isNotEmpty ? opt.structure : pt.structure,
              usage: opt.usage.isNotEmpty ? opt.usage : pt.explanation,
            );
          }
        }
      }
    }

    // 3. Parse questions
    final questionsList = <GrammarQuestion>[];
    if (map['questions'] is List) {
      for (var q in (map['questions'] as List)) {
        if (q is Map) {
          questionsList.add(GrammarQuestion.fromMap(Map<String, dynamic>.from(q)));
        }
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
