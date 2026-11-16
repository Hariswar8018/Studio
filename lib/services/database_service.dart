import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/sample_grammar_data.dart';
import '../models/grammar_model.dart';
import '../models/vocab_model.dart';
import '../models/kanji_model.dart';
import '../models/srs_progress_model.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService extends ChangeNotifier {
  final bool useFirebase;
  final FirebaseFirestore? _db;

  DatabaseService({this.useFirebase = true})
      : _db = useFirebase ? FirebaseFirestore.instance : null {
    _initLocalData();
  }

  // --- Active Level Selection State ---
  String _selectedLevel = 'N2';
  bool _hasSelectedLevel = false;
  bool _onboardingCompleted = false;

  String get selectedLevel => _selectedLevel;
  bool get hasSelectedLevel => _hasSelectedLevel;
  bool get isOnboardingCompleted => _onboardingCompleted;

  Future<void> setOnboardingCompleted(bool completed) async {
    _onboardingCompleted = completed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', completed);
    notifyListeners();
  }

  Future<void> setSelectedLevel(String level) async {
    _selectedLevel = level.toUpperCase();
    _hasSelectedLevel = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_jlpt_level', _selectedLevel);
    await prefs.setBool('has_selected_jlpt_level', true);
    notifyListeners();
  }

  // --- Grammar State ---
  final List<GrammarTopicModel> _cachedTopics = [];
  final Map<String, SrsProgressModel> _cachedSrsProgress = {};
  final Set<String> _completedTopicIds = {};

  List<GrammarTopicModel> get topics => List.unmodifiable(_cachedTopics);
  Set<String> get completedTopicIds => Set.unmodifiable(_completedTopicIds);
  Map<String, SrsProgressModel> get srsProgress => Map.unmodifiable(_cachedSrsProgress);

  // --- Vocabulary State ---
  final List<VocabularyTopicModel> _cachedVocabTopics = [];
  final Set<String> _completedVocabIds = {};

  List<VocabularyTopicModel> get vocabTopics => List.unmodifiable(_cachedVocabTopics);
  Set<String> get completedVocabIds => Set.unmodifiable(_completedVocabIds);

  // --- Kanji State ---
  final List<KanjiTopicModel> _cachedKanjiTopics = [];
  final Set<String> _completedKanjiIds = {};

  List<KanjiTopicModel> get kanjiTopics => List.unmodifiable(_cachedKanjiTopics);
  Set<String> get completedKanjiIds => Set.unmodifiable(_completedKanjiIds);

  int get totalAttempts {
    int total = 0;
    for (final s in _cachedSrsProgress.values) {
      total += s.correctCount + s.wrongCount;
    }
    return total;
  }

  int get totalCorrectAttempts {
    int total = 0;
    for (final s in _cachedSrsProgress.values) {
      total += s.correctCount;
    }
    return total;
  }

  double get overallAccuracyRate {
    final attempts = totalAttempts;
    if (attempts == 0) return 0.0;
    return (totalCorrectAttempts / attempts) * 100.0;
  }

  int get srsDueCount => _cachedSrsProgress.values.where((s) => s.isDue).length;

  bool isTopicCompleted(String topicId) => _completedTopicIds.contains(topicId);

  Future<void> markTopicCompleted(String topicId) async {
    _completedTopicIds.add(topicId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_grammar_topics', _completedTopicIds.toList());
    notifyListeners();
  }

  bool isVocabCompleted(String vocabId) => _completedVocabIds.contains(vocabId);

  Future<void> markVocabCompleted(String vocabId) async {
    _completedVocabIds.add(vocabId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_vocab_topics', _completedVocabIds.toList());
    notifyListeners();
  }

  bool isKanjiCompleted(String kanjiId) => _completedKanjiIds.contains(kanjiId);

  Future<void> markKanjiCompleted(String kanjiId) async {
    _completedKanjiIds.add(kanjiId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_kanji_topics', _completedKanjiIds.toList());
    notifyListeners();
  }

  Future<void> init() async {
    await _initLocalData();
  }

  Future<void> loadTopics() async {
    await _initLocalData();
  }

  Future<void> _initLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Level Selection & Onboarding Status
    _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    _hasSelectedLevel = prefs.getBool('has_selected_jlpt_level') ?? false;
    _selectedLevel = prefs.getString('selected_jlpt_level') ?? 'N2';

    // 2. Grammar Topics
    final localJsonList = prefs.getStringList('local_grammar_topics');
    if (localJsonList != null && localJsonList.isNotEmpty) {
      _cachedTopics.clear();
      for (var s in localJsonList) {
        try {
          _cachedTopics.add(GrammarTopicModel.fromJsonString(s));
        } catch (_) {}
      }
    } else {
      _cachedTopics.clear();
      _cachedTopics.addAll(SampleGrammarData.getInitialSampleGrammarTopics());
      await _persistLocalTopics();
    }

    // 3. Vocabulary Topics
    final localVocabList = prefs.getStringList('local_vocab_topics');
    if (localVocabList != null && localVocabList.isNotEmpty) {
      _cachedVocabTopics.clear();
      for (var s in localVocabList) {
        try {
          _cachedVocabTopics.add(VocabularyTopicModel.fromJson(s));
        } catch (_) {}
      }
    } else {
      _cachedVocabTopics.clear();
      _cachedVocabTopics.addAll(SampleGrammarData.getInitialSampleVocabTopics());
      await _persistLocalVocabTopics();
    }

    // 4. Kanji Topics
    final localKanjiList = prefs.getStringList('local_kanji_topics');
    if (localKanjiList != null && localKanjiList.isNotEmpty) {
      _cachedKanjiTopics.clear();
      for (var s in localKanjiList) {
        try {
          _cachedKanjiTopics.add(KanjiTopicModel.fromJson(s));
        } catch (_) {}
      }
    } else {
      _cachedKanjiTopics.clear();
      _cachedKanjiTopics.addAll(SampleGrammarData.getInitialSampleKanjiTopics());
      await _persistLocalKanjiTopics();
    }

    // 5. Remote Firestore sync
    if (useFirebase && _db != null) {
      try {
        // Grammar
        final snapshot = await _db.collection('grammar_topics').get();
        if (snapshot.docs.isNotEmpty) {
          final remoteList = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return GrammarTopicModel.fromMap(data);
          }).toList();
          for (final r in remoteList) {
            _cachedTopics.removeWhere((t) => t.id == r.id);
            _cachedTopics.add(r);
          }
          await _persistLocalTopics();
        }

        // Vocabulary
        final vocabSnapshot = await _db.collection('vocabulary_topics').get();
        if (vocabSnapshot.docs.isNotEmpty) {
          final remoteVocab = vocabSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return VocabularyTopicModel.fromMap(data);
          }).toList();
          for (final r in remoteVocab) {
            _cachedVocabTopics.removeWhere((t) => t.id == r.id);
            _cachedVocabTopics.add(r);
          }
          await _persistLocalVocabTopics();
        }

        // Kanji
        final kanjiSnapshot = await _db.collection('kanji_topics').get();
        if (kanjiSnapshot.docs.isNotEmpty) {
          final remoteKanji = kanjiSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return KanjiTopicModel.fromMap(data);
          }).toList();
          for (final r in remoteKanji) {
            _cachedKanjiTopics.removeWhere((t) => t.id == r.id);
            _cachedKanjiTopics.add(r);
          }
          await _persistLocalKanjiTopics();
        }
      } catch (e) {
        debugPrint('Firestore remote sync error: $e');
      }
    }

    // 6. Load local SRS items
    final localSrsList = prefs.getStringList('local_grammar_srs');
    if (localSrsList != null) {
      for (var s in localSrsList) {
        try {
          final map = json.decode(s);
          final progress = SrsProgressModel.fromMap(map, map['id'] ?? '');
          _cachedSrsProgress[progress.questionId.toString()] = progress;
        } catch (_) {}
      }
    }

    // 7. Load completed sets
    final completedGrammar = prefs.getStringList('completed_grammar_topics');
    if (completedGrammar != null) {
      _completedTopicIds.clear();
      _completedTopicIds.addAll(completedGrammar);
    }

    final completedVocab = prefs.getStringList('completed_vocab_topics');
    if (completedVocab != null) {
      _completedVocabIds.clear();
      _completedVocabIds.addAll(completedVocab);
    }

    final completedKanji = prefs.getStringList('completed_kanji_topics');
    if (completedKanji != null) {
      _completedKanjiIds.clear();
      _completedKanjiIds.addAll(completedKanji);
    }

    notifyListeners();
  }

  Future<void> _persistLocalTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cachedTopics.map((t) => t.toJsonString()).toList();
    await prefs.setStringList('local_grammar_topics', jsonList);
  }

  Future<void> _persistLocalVocabTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cachedVocabTopics.map((t) => t.toJson()).toList();
    await prefs.setStringList('local_vocab_topics', jsonList);
  }

  Future<void> _persistLocalKanjiTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cachedKanjiTopics.map((t) => t.toJson()).toList();
    await prefs.setStringList('local_kanji_topics', jsonList);
  }

  Future<void> _persistLocalSrs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cachedSrsProgress.values.map((s) => json.encode(s.toMap())).toList();
    await prefs.setStringList('local_grammar_srs', jsonList);
  }

  // ================= GRAMMAR TOPICS =================

  List<GrammarTopicModel> getTopicsForLevel(String level) {
    if (level.toUpperCase() == 'ALL') return topics;
    return _cachedTopics.where((t) => t.jlpt.toUpperCase() == level.toUpperCase()).toList();
  }

  Future<List<GrammarTopicModel>> getGrammarTopics({String? jlptLevel}) async {
    if (jlptLevel != null && jlptLevel.toUpperCase() != 'ALL') {
      return getTopicsForLevel(jlptLevel);
    }
    return topics;
  }

  GrammarTopicModel? getTopicById(String id) {
    try {
      return _cachedTopics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  GrammarTopicModel? getTopicForQuestion(dynamic questionId) {
    for (final topic in _cachedTopics) {
      for (final q in topic.questions) {
        if (q.id == questionId) return topic;
      }
    }
    return null;
  }

  Future<void> saveGrammarTopic(GrammarTopicModel topic) async {
    final index = _cachedTopics.indexWhere((t) => t.id == topic.id);
    if (index >= 0) {
      _cachedTopics[index] = topic;
    } else {
      _cachedTopics.add(topic);
    }

    if (useFirebase && _db != null) {
      try {
        await _db.collection('grammar_topics').doc(topic.id).set(topic.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveGrammarTopic error: $e');
      }
    }

    await _persistLocalTopics();
    notifyListeners();
  }

  Future<void> saveTopic(GrammarTopicModel topic) => saveGrammarTopic(topic);

  Future<void> deleteTopic(String topicId) async {
    _cachedTopics.removeWhere((t) => t.id == topicId);
    _completedTopicIds.remove(topicId);

    if (useFirebase && _db != null) {
      try {
        await _db.collection('grammar_topics').doc(topicId).delete();
      } catch (e) {
        debugPrint('Firestore deleteTopic error: $e');
      }
    }

    await _persistLocalTopics();
    notifyListeners();
  }

  // ================= VOCABULARY TOPICS =================

  List<VocabularyTopicModel> getVocabTopicsForLevel(String level) {
    if (level.toUpperCase() == 'ALL') return vocabTopics;
    return _cachedVocabTopics.where((t) => t.jlpt.toUpperCase() == level.toUpperCase()).toList();
  }

  VocabularyTopicModel? getVocabTopicById(String id) {
    try {
      return _cachedVocabTopics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveVocabTopic(VocabularyTopicModel topic) async {
    final index = _cachedVocabTopics.indexWhere((t) => t.id == topic.id);
    if (index >= 0) {
      _cachedVocabTopics[index] = topic;
    } else {
      _cachedVocabTopics.add(topic);
    }

    if (useFirebase && _db != null) {
      try {
        await _db.collection('vocabulary_topics').doc(topic.id).set(topic.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveVocabTopic error: $e');
      }
    }

    await _persistLocalVocabTopics();
    notifyListeners();
  }

  Future<void> deleteVocabTopic(String topicId) async {
    _cachedVocabTopics.removeWhere((t) => t.id == topicId);
    _completedVocabIds.remove(topicId);

    if (useFirebase && _db != null) {
      try {
        await _db.collection('vocabulary_topics').doc(topicId).delete();
      } catch (e) {
        debugPrint('Firestore deleteVocabTopic error: $e');
      }
    }

    await _persistLocalVocabTopics();
    notifyListeners();
  }

  // ================= KANJI TOPICS =================

  List<KanjiTopicModel> getKanjiTopicsForLevel(String level) {
    if (level.toUpperCase() == 'ALL') return kanjiTopics;
    return _cachedKanjiTopics.where((t) => t.jlpt.toUpperCase() == level.toUpperCase()).toList();
  }

  KanjiTopicModel? getKanjiTopicById(String id) {
    try {
      return _cachedKanjiTopics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveKanjiTopic(KanjiTopicModel topic) async {
    final index = _cachedKanjiTopics.indexWhere((t) => t.id == topic.id);
    if (index >= 0) {
      _cachedKanjiTopics[index] = topic;
    } else {
      _cachedKanjiTopics.add(topic);
    }

    if (useFirebase && _db != null) {
      try {
        await _db.collection('kanji_topics').doc(topic.id).set(topic.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveKanjiTopic error: $e');
      }
    }

    await _persistLocalKanjiTopics();
    notifyListeners();
  }

  Future<void> deleteKanjiTopic(String topicId) async {
    _cachedKanjiTopics.removeWhere((t) => t.id == topicId);
    _completedKanjiIds.remove(topicId);

    if (useFirebase && _db != null) {
      try {
        await _db.collection('kanji_topics').doc(topicId).delete();
      } catch (e) {
        debugPrint('Firestore deleteKanjiTopic error: $e');
      }
    }

    await _persistLocalKanjiTopics();
    notifyListeners();
  }

  // ================= METRICS & STATS =================

  int get totalGrammarCount => _cachedTopics.length;
  int get completedGrammarCount => _completedTopicIds.length;
  int get totalVocabTopicsCount => _cachedVocabTopics.length;
  int get totalVocabWordsCount => _cachedVocabTopics.fold(0, (total, t) => total + t.vocabulary.length);
  int get completedVocabCount => _completedVocabIds.length;
  int get totalKanjiTopicsCount => _cachedKanjiTopics.length;
  int get totalKanjiCharactersCount => _cachedKanjiTopics.fold(0, (total, t) => total + t.kanji.length);
  int get completedKanjiCount => _completedKanjiIds.length;
  int get totalAllLessonsCount => totalGrammarCount + totalVocabTopicsCount + totalKanjiTopicsCount;
  int get totalCompletedLessonsCount => completedGrammarCount + completedVocabCount + completedKanjiCount;

  // ================= 60% PREMIUM LOCK HELPERS =================

  bool isGrammarTopicLocked(String topicId, bool isPremium) {
    if (isPremium) return false;
    final topic = getTopicById(topicId);
    if (topic == null) return false;
    final list = getTopicsForLevel(topic.jlpt);
    if (list.length <= 1) return false;
    final freeCount = (list.length * 0.4).ceil().clamp(1, list.length);
    final index = list.indexWhere((t) => t.id == topicId);
    return index >= freeCount;
  }

  bool isVocabTopicLocked(String topicId, bool isPremium) {
    if (isPremium) return false;
    final topic = getVocabTopicById(topicId);
    if (topic == null) return false;
    final list = getVocabTopicsForLevel(topic.jlpt);
    if (list.length <= 1) return false;
    final freeCount = (list.length * 0.4).ceil().clamp(1, list.length);
    final index = list.indexWhere((t) => t.id == topicId);
    return index >= freeCount;
  }

  bool isKanjiTopicLocked(String topicId, bool isPremium) {
    if (isPremium) return false;
    final topic = getKanjiTopicById(topicId);
    if (topic == null) return false;
    final list = getKanjiTopicsForLevel(topic.jlpt);
    if (list.length <= 1) return false;
    final freeCount = (list.length * 0.4).ceil().clamp(1, list.length);
    final index = list.indexWhere((t) => t.id == topicId);
    return index >= freeCount;
  }

  // ================= SRS & TEST POOL =================

  int get difficultCount => getDifficultQuestions().length;
  int get easyCount => getEasyQuestions().length;

  List<GrammarQuestion> getDueSrsQuestions({String? level}) {
    final List<GrammarQuestion> due = [];
    for (final s in _cachedSrsProgress.values) {
      if (s.isDue) {
        if (level != null && level.toUpperCase() != 'ALL' && s.jlpt.toUpperCase() != level.toUpperCase()) {
          continue;
        }
        final q = _findQuestionById(s.questionId);
        if (q != null && !due.any((item) => item.id == q.id)) {
          due.add(q);
        }
      }
    }
    return due;
  }

  SrsProgressModel? getQuestionProgress(dynamic questionId) {
    return _cachedSrsProgress[questionId.toString()];
  }

  List<GrammarQuestion> getDifficultQuestions() {
    final List<GrammarQuestion> list = [];
    for (final s in _cachedSrsProgress.values) {
      if (s.isDifficult) {
        final q = _findQuestionById(s.questionId);
        if (q != null && !list.any((item) => item.id == q.id)) {
          list.add(q);
        }
      }
    }
    return list;
  }

  List<GrammarQuestion> getEasyQuestions() {
    final List<GrammarQuestion> list = [];
    for (final s in _cachedSrsProgress.values) {
      if (s.isMasteredEasy) {
        final q = _findQuestionById(s.questionId);
        if (q != null && !list.any((item) => item.id == q.id)) {
          list.add(q);
        }
      }
    }
    return list;
  }

  GrammarQuestion? _findQuestionById(dynamic questionId) {
    for (final topic in _cachedTopics) {
      for (final q in topic.questions) {
        if (q.id == questionId) return q;
      }
    }
    return null;
  }

  List<GrammarQuestion> generateRandomTest({
    String? level,
    int? count,
    bool difficultOnly = false,
  }) {
    List<GrammarQuestion> pool = [];

    if (difficultOnly) {
      pool = getDifficultQuestions();
      if (level != null && level.toUpperCase() != 'ALL') {
        pool = pool.where((q) {
          final t = getTopicForQuestion(q.id);
          return t?.jlpt.toUpperCase() == level.toUpperCase();
        }).toList();
      }
    } else {
      final availableTopics = (level != null && level.toUpperCase() != 'ALL')
          ? getTopicsForLevel(level)
          : _cachedTopics;

      for (final t in availableTopics) {
        for (final q in t.questions) {
          pool.add(q);
        }
      }
    }

    pool.shuffle();
    if (count != null && count > 0 && pool.length > count) {
      return pool.take(count).toList();
    }
    return pool;
  }

  Future<void> recordQuestionAttempt(dynamic questionId, bool isCorrect) async {
    GrammarTopicModel? parentTopic;
    GrammarQuestion? targetQuestion;

    for (final t in _cachedTopics) {
      for (final q in t.questions) {
        if (q.id == questionId) {
          parentTopic = t;
          targetQuestion = q;
          break;
        }
      }
      if (parentTopic != null) break;
    }

    if (parentTopic == null || targetQuestion == null) return;

    final key = questionId.toString();
    final existing = _cachedSrsProgress[key] ??
        SrsProgressModel(
          id: 'srs_$questionId',
          userId: 'current_user',
          topicId: parentTopic.id,
          questionId: questionId,
          jlpt: parentTopic.jlpt,
          stage: 0,
          nextReviewDate: DateTime.now().add(const Duration(days: 1)),
          lastReviewedDate: DateTime.now(),
        );

    final updated = existing.copyWithResult(isCorrect: isCorrect);
    _cachedSrsProgress[key] = updated;

    if (useFirebase && _db != null) {
      try {
        await _db.collection('grammar_srs_progress').doc('srs_$questionId').set(updated.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore recordQuestionAttempt error: $e');
      }
    }

    await _persistLocalSrs();
    notifyListeners();
  }

  // --- USER PROFILE & POINTS ---

  Future<UserModel?> getUser(String uid) async {
    if (useFirebase && _db != null) {
      try {
        final doc = await _db.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('Firestore getUser error: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('local_user_$uid');
    if (saved != null) {
      try {
        return UserModel.fromMap(json.decode(saved), uid);
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveUser(UserModel user) async {
    if (useFirebase && _db != null) {
      try {
        await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore saveUser error: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_user_${user.uid}', json.encode(user.toMap()));
    notifyListeners();
  }

  Future<void> addPoints(String uid, int delta) async {
    final user = await getUser(uid);
    if (user != null) {
      final updated = user.copyWith(points: user.points + delta);
      await saveUser(updated);
    }
  }
}
