import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/grammar_model.dart';
import '../models/vocab_model.dart';
import '../models/kanji_model.dart';
import '../models/report_model.dart';
import '../models/srs_progress_model.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPracticeProgress {
  final String topicId;
  final String category;
  final int currentIndex;
  final int correctCount;
  final List<String> questionIds;
  final bool isFullPractice;
  final DateTime timestamp;

  SavedPracticeProgress({
    required this.topicId,
    required this.category,
    required this.currentIndex,
    required this.correctCount,
    required this.questionIds,
    this.isFullPractice = true,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'topicId': topicId,
    'category': category,
    'currentIndex': currentIndex,
    'correctCount': correctCount,
    'questionIds': questionIds,
    'isFullPractice': isFullPractice,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SavedPracticeProgress.fromMap(Map<String, dynamic> map) => SavedPracticeProgress(
    topicId: map['topicId']?.toString() ?? '',
    category: map['category']?.toString() ?? 'grammar',
    currentIndex: (map['currentIndex'] as num?)?.toInt() ?? 0,
    correctCount: (map['correctCount'] as num?)?.toInt() ?? 0,
    questionIds: (map['questionIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    isFullPractice: map['isFullPractice'] == true,
    timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
  );
}

class DatabaseService extends ChangeNotifier {
  final bool useFirebase;
  final FirebaseFirestore? _db;
  bool _isInitialized = false;

  DatabaseService({this.useFirebase = true})
      : _db = useFirebase ? FirebaseFirestore.instance : null;

  // --- Admin Authentication Security Gate ---
  bool _isAdminAuthenticated() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final email = user.email?.trim().toLowerCase();
      return email != null && UserModel.adminEmails.contains(email);
    } catch (_) {
      return false;
    }
  }

  void _assertAdminAuthenticated(String action) {
    if (!_isAdminAuthenticated()) {
      debugPrint('SECURITY VIOLATION: $action blocked. User is not an authenticated Admin Gmail.');
      throw StateError('Unauthorized: Only authenticated Admin Gmail can perform $action.');
    }
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

  // --- Natural Alphanumeric Sorting (1 to 100, then A-Z, a-z) ---
  static int naturalAlphanumericCompare(String a, String b) {
    final regExp = RegExp(r'(\d+|\D+)');
    final matchesA = regExp.allMatches(a.trim()).map((m) => m.group(0)!).toList();
    final matchesB = regExp.allMatches(b.trim()).map((m) => m.group(0)!).toList();

    final minLen = math.min(matchesA.length, matchesB.length);
    for (int i = 0; i < minLen; i++) {
      final tokenA = matchesA[i];
      final tokenB = matchesB[i];

      final numA = int.tryParse(tokenA);
      final numB = int.tryParse(tokenB);

      if (numA != null && numB != null) {
        final cmp = numA.compareTo(numB);
        if (cmp != 0) return cmp;
      } else if (numA != null && numB == null) {
        // Numbers 1..100 come before letters A-Z, a-z
        return -1;
      } else if (numA == null && numB != null) {
        return 1;
      } else {
        final cmp = tokenA.compareTo(tokenB);
        if (cmp != 0) return cmp;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
  }

  void _sortCachedTopics() {
    _cachedTopics.sort((a, b) => naturalAlphanumericCompare(a.title, b.title));
  }

  void _sortCachedVocabTopics() {
    _cachedVocabTopics.sort((a, b) => naturalAlphanumericCompare(a.title, b.title));
  }

  void _sortCachedKanjiTopics() {
    _cachedKanjiTopics.sort((a, b) => naturalAlphanumericCompare(a.title, b.title));
  }

  // --- Grammar State ---
  final List<GrammarTopicModel> _cachedTopics = [];
  final Map<String, SrsProgressModel> _cachedSrsProgress = {};
  final Set<String> _completedTopicIds = {};

  List<GrammarTopicModel> get topics {
    _sortCachedTopics();
    return List.unmodifiable(_cachedTopics);
  }
  Set<String> get completedTopicIds => Set.unmodifiable(_completedTopicIds);
  Map<String, SrsProgressModel> get srsProgress => Map.unmodifiable(_cachedSrsProgress);

  // --- Vocabulary State ---
  final List<VocabularyTopicModel> _cachedVocabTopics = [];
  final Set<String> _completedVocabIds = {};

  List<VocabularyTopicModel> get vocabTopics {
    _sortCachedVocabTopics();
    return List.unmodifiable(_cachedVocabTopics);
  }
  Set<String> get completedVocabIds => Set.unmodifiable(_completedVocabIds);

  // --- Kanji State ---
  final List<KanjiTopicModel> _cachedKanjiTopics = [];
  final Set<String> _completedKanjiIds = {};

  List<KanjiTopicModel> get kanjiTopics {
    _sortCachedKanjiTopics();
    return List.unmodifiable(_cachedKanjiTopics);
  }
  Set<String> get completedKanjiIds => Set.unmodifiable(_completedKanjiIds);

  // --- Reports State ---
  final List<QuestionReportModel> _cachedReports = [];
  List<QuestionReportModel> get reports => List.unmodifiable(_cachedReports);
  int get pendingReportsCount => _cachedReports.where((r) => r.status == 'pending').length;

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

  // --- Practice Test Resume & Progress Persistence ---

  Future<void> savePracticeProgress({
    required String topicId,
    required String category,
    required int currentIndex,
    required int correctCount,
    required List<dynamic> questionIds,
    bool isFullPractice = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = SavedPracticeProgress(
      topicId: topicId,
      category: category,
      currentIndex: currentIndex,
      correctCount: correctCount,
      questionIds: questionIds.map((e) => e.toString()).toList(),
      isFullPractice: isFullPractice,
      timestamp: DateTime.now(),
    );
    await prefs.setString('practice_progress_$topicId', json.encode(progress.toMap()));
  }

  Future<SavedPracticeProgress?> getPracticeProgress(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('practice_progress_$topicId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = json.decode(raw);
      return SavedPracticeProgress.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPracticeProgress(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('practice_progress_$topicId');
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
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

    // 2. Grammar Topics (Load saved lessons without automatic overwrite)
    final localJsonList = prefs.getStringList('local_grammar_topics');
    if (localJsonList != null && localJsonList.isNotEmpty) {
      _cachedTopics.clear();
      for (var s in localJsonList) {
        try {
          _cachedTopics.add(GrammarTopicModel.fromJsonString(s));
        } catch (_) {}
      }
    }

    // 3. Vocabulary Topics (Load saved lessons without automatic overwrite)
    final localVocabList = prefs.getStringList('local_vocab_topics');
    if (localVocabList != null && localVocabList.isNotEmpty) {
      _cachedVocabTopics.clear();
      for (var s in localVocabList) {
        try {
          _cachedVocabTopics.add(VocabularyTopicModel.fromJson(s));
        } catch (_) {}
      }
    }

    // 4. Kanji Topics (Load saved lessons without automatic overwrite)
    final localKanjiList = prefs.getStringList('local_kanji_topics');
    if (localKanjiList != null && localKanjiList.isNotEmpty) {
      _cachedKanjiTopics.clear();
      for (var s in localKanjiList) {
        try {
          _cachedKanjiTopics.add(KanjiTopicModel.fromJson(s));
        } catch (_) {}
      }
    }

    // Pure production: Remove any artificial sample data, never auto-seed fake lessons
    _cachedTopics.removeWhere((t) => t.id.startsWith('sample_'));
    _cachedVocabTopics.removeWhere((t) => t.id.startsWith('sample_'));
    _cachedKanjiTopics.removeWhere((t) => t.id.startsWith('sample_'));

    // 5. Load local SRS items
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

    // 6. Load completed sets
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

    // 7. Load local Reports
    final localReportsList = prefs.getStringList('local_question_reports');
    if (localReportsList != null) {
      _cachedReports.clear();
      for (var s in localReportsList) {
        try {
          _cachedReports.add(QuestionReportModel.fromJson(s));
        } catch (_) {}
      }
    }

    _sortCachedTopics();
    _sortCachedVocabTopics();
    _sortCachedKanjiTopics();

    notifyListeners();

    // 7. Background Firestore remote sync & real-time updates for all users
    if (useFirebase && _db != null) {
      _syncRemoteTopicsInBackground();
      _listenToRemoteTopicsRealtime();
    }
  }

  void _listenToRemoteTopicsRealtime() {
    final firestore = _db;
    if (firestore == null) return;

    // Real-time listener for Grammar Topics
    firestore.collection('grammar_topics').snapshots().listen((snapshot) {
      final remoteList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GrammarTopicModel.fromMap(data);
      }).toList();
      _cachedTopics.clear();
      _cachedTopics.addAll(remoteList);
      _cachedTopics.removeWhere((t) => t.id.startsWith('sample_'));
      _sortCachedTopics();
      _persistLocalTopics();
      notifyListeners();
    }, onError: (e) => debugPrint('Realtime grammar error: $e'));

    // Real-time listener for Vocabulary Topics
    firestore.collection('vocabulary_topics').snapshots().listen((snapshot) {
      final remoteList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return VocabularyTopicModel.fromMap(data);
      }).toList();
      _cachedVocabTopics.clear();
      _cachedVocabTopics.addAll(remoteList);
      _cachedVocabTopics.removeWhere((t) => t.id.startsWith('sample_'));
      _sortCachedVocabTopics();
      _persistLocalVocabTopics();
      notifyListeners();
    }, onError: (e) => debugPrint('Realtime vocab error: $e'));

    // Real-time listener for Kanji Topics
    firestore.collection('kanji_topics').snapshots().listen((snapshot) {
      final remoteList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return KanjiTopicModel.fromMap(data);
      }).toList();
      _cachedKanjiTopics.clear();
      _cachedKanjiTopics.addAll(remoteList);
      _cachedKanjiTopics.removeWhere((t) => t.id.startsWith('sample_'));
      _sortCachedKanjiTopics();
      _persistLocalKanjiTopics();
      notifyListeners();
    }, onError: (e) => debugPrint('Realtime kanji error: $e'));
  }

  Future<void> _syncRemoteTopicsInBackground() async {
    final firestore = _db;
    if (firestore == null) return;
    try {
      bool anyUpdated = false;

      // 1. Grammar
      try {
        final snapshot = await firestore.collection('grammar_topics').get().timeout(const Duration(seconds: 15));
        if (snapshot.docs.isNotEmpty) {
          final remoteList = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return GrammarTopicModel.fromMap(data);
          }).toList();
          _cachedTopics.clear();
          _cachedTopics.addAll(remoteList);
          _cachedTopics.removeWhere((t) => t.id.startsWith('sample_'));
          _sortCachedTopics();
          await _persistLocalTopics();
          anyUpdated = true;
        }
      } catch (e) {
        debugPrint('Firestore grammar sync notice: $e');
      }

      // 2. Vocabulary
      try {
        final vocabSnapshot = await firestore.collection('vocabulary_topics').get().timeout(const Duration(seconds: 15));
        if (vocabSnapshot.docs.isNotEmpty) {
          final remoteVocab = vocabSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return VocabularyTopicModel.fromMap(data);
          }).toList();
          _cachedVocabTopics.clear();
          _cachedVocabTopics.addAll(remoteVocab);
          _cachedVocabTopics.removeWhere((t) => t.id.startsWith('sample_'));
          _sortCachedVocabTopics();
          await _persistLocalVocabTopics();
          anyUpdated = true;
        }
      } catch (e) {
        debugPrint('Firestore vocab sync notice: $e');
      }

      // 3. Kanji
      try {
        final kanjiSnapshot = await firestore.collection('kanji_topics').get().timeout(const Duration(seconds: 15));
        if (kanjiSnapshot.docs.isNotEmpty) {
          final remoteKanji = kanjiSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return KanjiTopicModel.fromMap(data);
          }).toList();
          _cachedKanjiTopics.clear();
          _cachedKanjiTopics.addAll(remoteKanji);
          _cachedKanjiTopics.removeWhere((t) => t.id.startsWith('sample_'));
          _sortCachedKanjiTopics();
          await _persistLocalKanjiTopics();
          anyUpdated = true;
        }
      } catch (e) {
        debugPrint('Firestore kanji sync notice: $e');
      }

      // 4. Reports
      try {
        final reportsSnapshot = await firestore.collection('question_reports').get().timeout(const Duration(seconds: 15));
        if (reportsSnapshot.docs.isNotEmpty) {
          final remoteReports = reportsSnapshot.docs.map((doc) {
            return QuestionReportModel.fromMap(doc.data(), doc.id);
          }).toList();
          _cachedReports.clear();
          _cachedReports.addAll(remoteReports);
          await _persistLocalReports();
        }
      } catch (e) {
        debugPrint('Firestore reports sync notice: $e');
      }

      if (anyUpdated) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firestore remote sync error: $e');
    }
  }

  Future<void> _persistLocalReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cachedReports.map((r) => r.toJson()).toList();
    await prefs.setStringList('local_question_reports', jsonList);
  }

  Future<void> submitQuestionReport(QuestionReportModel report) async {
    final index = _cachedReports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      _cachedReports[index] = report;
    } else {
      _cachedReports.insert(0, report);
    }
    await _persistLocalReports();

    if (useFirebase && _db != null) {
      try {
        await _db.collection('question_reports').doc(report.id).set(report.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore submitQuestionReport error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> updateReportStatus(String reportId, String newStatus) async {
    final index = _cachedReports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      final old = _cachedReports[index];
      _cachedReports[index] = QuestionReportModel(
        id: old.id,
        questionId: old.questionId,
        topicId: old.topicId,
        category: old.category,
        level: old.level,
        questionText: old.questionText,
        reportedReason: old.reportedReason,
        userComment: old.userComment,
        createdAt: old.createdAt,
        status: newStatus,
        options: old.options,
        correctOption: old.correctOption,
      );
      await _persistLocalReports();
      if (useFirebase && _db != null) {
        try {
          await _db.collection('question_reports').doc(reportId).update({'status': newStatus});
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> deleteReport(String reportId) async {
    _cachedReports.removeWhere((r) => r.id == reportId);
    await _persistLocalReports();
    if (useFirebase && _db != null) {
      try {
        await _db.collection('question_reports').doc(reportId).delete();
      } catch (e) {
        debugPrint('Firestore deleteReport error: $e');
      }
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
    final list = level.toUpperCase() == 'ALL'
        ? List<GrammarTopicModel>.from(_cachedTopics)
        : _cachedTopics.where((t) => t.jlpt.toUpperCase() == level.toUpperCase()).toList();
    list.sort((a, b) => naturalAlphanumericCompare(a.title, b.title));
    return list;
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
    _assertAdminAuthenticated('saveGrammarTopic');
    var finalTopic = topic;
    final index = _cachedTopics.indexWhere((t) => t.id == topic.id);
    if (index >= 0) {
      final existing = _cachedTopics[index];
      if (existing.title != topic.title || existing.questions.length != topic.questions.length) {
        // Prevent replacement: assign safe unique ID to preserve existing lesson
        final safeId = '${topic.id}_${DateTime.now().millisecondsSinceEpoch}';
        finalTopic = GrammarTopicModel(
          id: safeId,
          title: topic.title,
          jlpt: topic.jlpt,
          section: topic.section,
          category: topic.category,
          tags: topic.tags,
          description: topic.description,
          grammarPoints: topic.grammarPoints,
          globalOptions: topic.globalOptions,
          instructions: topic.instructions,
          questions: topic.questions,
          metadata: topic.metadata,
        );
        _cachedTopics.add(finalTopic);
      } else {
        _cachedTopics[index] = finalTopic;
      }
    } else {
      _cachedTopics.add(finalTopic);
    }

    if (useFirebase && _db != null) {
      // Direct Firestore push: throws if Firestore fails so Admin is alerted immediately
      await _db.collection('grammar_topics').doc(finalTopic.id).set(finalTopic.toMap(), SetOptions(merge: true));
    }

    final cachedIdx = _cachedTopics.indexWhere((t) => t.id == finalTopic.id);
    if (cachedIdx >= 0) {
      _cachedTopics[cachedIdx] = finalTopic;
    } else {
      _cachedTopics.add(finalTopic);
    }
    await _persistLocalTopics();
    _sortCachedTopics();
    notifyListeners();
  }

  Future<void> saveGrammarTopicsBatch(List<GrammarTopicModel> topicsList) async {
    _assertAdminAuthenticated('saveGrammarTopicsBatch');
    if (topicsList.isEmpty) return;

    if (useFirebase && _db != null) {
      final batch = _db.batch();
      for (final topic in topicsList) {
        final docRef = _db.collection('grammar_topics').doc(topic.id);
        batch.set(docRef, topic.toMap(), SetOptions(merge: true));
      }
      // Commit directly to Firestore: throws if error occurs
      await batch.commit();
    }

    for (final topic in topicsList) {
      final index = _cachedTopics.indexWhere((t) => t.id == topic.id);
      if (index >= 0) {
        _cachedTopics[index] = topic;
      } else {
        _cachedTopics.add(topic);
      }
    }

    _sortCachedTopics();
    await _persistLocalTopics();
    notifyListeners();
  }

  Future<void> saveTopic(GrammarTopicModel topic) => saveGrammarTopic(topic);

  Future<void> updateGrammarTopicTitle(String topicId, String newTitle) async {
    _assertAdminAuthenticated('updateGrammarTopicTitle');
    final index = _cachedTopics.indexWhere((t) => t.id == topicId);
    if (index >= 0) {
      final old = _cachedTopics[index];
      _cachedTopics[index] = GrammarTopicModel(
        id: old.id,
        title: newTitle,
        jlpt: old.jlpt,
        section: old.section,
        category: old.category,
        tags: old.tags,
        description: old.description,
        grammarPoints: old.grammarPoints,
        globalOptions: old.globalOptions,
        instructions: old.instructions,
        questions: old.questions,
        metadata: old.metadata,
      );
      _sortCachedTopics();
      await _persistLocalTopics();
      if (useFirebase && _db != null) {
        try {
          await _db.collection('grammar_topics').doc(topicId).update({'title': newTitle});
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> deleteTopic(String topicId) async {
    _assertAdminAuthenticated('deleteTopic');
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
    final list = level.toUpperCase() == 'ALL'
        ? List<VocabularyTopicModel>.from(_cachedVocabTopics)
        : _cachedVocabTopics.where((t) => t.jlpt.toUpperCase() == level.toUpperCase()).toList();
    list.sort((a, b) => naturalAlphanumericCompare(a.title, b.title));
    return list;
  }

  VocabularyTopicModel? getVocabTopicById(String id) {
    try {
      return _cachedVocabTopics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveVocabTopic(VocabularyTopicModel topic) async {
    _assertAdminAuthenticated('saveVocabTopic');
    var finalTopic = topic;
    final index = _cachedVocabTopics.indexWhere((t) => t.id == topic.id);
    if (index >= 0) {
      final existing = _cachedVocabTopics[index];
      if (existing.title != topic.title || existing.vocabulary.length != topic.vocabulary.length) {
        final safeId = '${topic.id}_${DateTime.now().millisecondsSinceEpoch}';
        finalTopic = VocabularyTopicModel(
          id: safeId,
          title: topic.title,
          jlpt: topic.jlpt,
          section: topic.section,
          tags: topic.tags,
          vocabulary: topic.vocabulary,
          metadata: topic.metadata,
        );
        _cachedVocabTopics.add(finalTopic);
      } else {
        _cachedVocabTopics[index] = finalTopic;
      }
    } else {
      _cachedVocabTopics.add(finalTopic);
    }

    if (useFirebase && _db != null) {
      // Direct Firestore push: throws if Firestore fails so Admin is alerted immediately
      await _db.collection('vocabulary_topics').doc(finalTopic.id).set(finalTopic.toMap(), SetOptions(merge: true));
    }

    final cachedIdx = _cachedVocabTopics.indexWhere((t) => t.id == finalTopic.id);
    if (cachedIdx >= 0) {
      _cachedVocabTopics[cachedIdx] = finalTopic;
    } else {
      _cachedVocabTopics.add(finalTopic);
    }
    await _persistLocalVocabTopics();
    _sortCachedVocabTopics();
    notifyListeners();
  }

  Future<void> saveVocabTopicsBatch(List<VocabularyTopicModel> topicsList) async {
    _assertAdminAuthenticated('saveVocabTopicsBatch');
    if (topicsList.isEmpty) return;

    if (useFirebase && _db != null) {
      final batch = _db.batch();
      for (final topic in topicsList) {
        final docRef = _db.collection('vocabulary_topics').doc(topic.id);
        batch.set(docRef, topic.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    }

    for (final topic in topicsList) {
      final index = _cachedVocabTopics.indexWhere((t) => t.id == topic.id);
      if (index >= 0) {
        _cachedVocabTopics[index] = topic;
      } else {
        _cachedVocabTopics.add(topic);
      }
    }

    _sortCachedVocabTopics();
    await _persistLocalVocabTopics();
    notifyListeners();
  }

  Future<void> updateVocabTopicTitle(String topicId, String newTitle) async {
    _assertAdminAuthenticated('updateVocabTopicTitle');
    final index = _cachedVocabTopics.indexWhere((t) => t.id == topicId);
    if (index >= 0) {
      final old = _cachedVocabTopics[index];
      _cachedVocabTopics[index] = VocabularyTopicModel(
        id: old.id,
        title: newTitle,
        jlpt: old.jlpt,
        section: old.section,
        tags: old.tags,
        vocabulary: old.vocabulary,
        metadata: old.metadata,
      );
      _sortCachedVocabTopics();
      await _persistLocalVocabTopics();
      if (useFirebase && _db != null) {
        try {
          await _db.collection('vocabulary_topics').doc(topicId).update({'title': newTitle});
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> deleteVocabTopic(String topicId) async {
    _assertAdminAuthenticated('deleteVocabTopic');
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
    final list = level.toUpperCase() == 'ALL'
        ? List<KanjiTopicModel>.from(_cachedKanjiTopics)
        : _cachedKanjiTopics.where((t) => t.jlpt.toUpperCase() == level.toUpperCase()).toList();
    list.sort((a, b) => naturalAlphanumericCompare(a.title, b.title));
    return list;
  }

  KanjiTopicModel? getKanjiTopicById(String id) {
    try {
      return _cachedKanjiTopics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveKanjiTopic(KanjiTopicModel topic) async {
    _assertAdminAuthenticated('saveKanjiTopic');
    var finalTopic = topic;
    final index = _cachedKanjiTopics.indexWhere((t) => t.id == topic.id);
    if (index >= 0) {
      final existing = _cachedKanjiTopics[index];
      if (existing.title != topic.title || existing.kanji.length != topic.kanji.length) {
        final safeId = '${topic.id}_${DateTime.now().millisecondsSinceEpoch}';
        finalTopic = KanjiTopicModel(
          id: safeId,
          title: topic.title,
          jlpt: topic.jlpt,
          section: topic.section,
          tags: topic.tags,
          kanji: topic.kanji,
          metadata: topic.metadata,
        );
        _cachedKanjiTopics.add(finalTopic);
      } else {
        _cachedKanjiTopics[index] = finalTopic;
      }
    } else {
      _cachedKanjiTopics.add(finalTopic);
    }

    if (useFirebase && _db != null) {
      // Direct Firestore push: throws if Firestore fails so Admin is alerted immediately
      await _db.collection('kanji_topics').doc(finalTopic.id).set(finalTopic.toMap(), SetOptions(merge: true));
    }

    final cachedIdx = _cachedKanjiTopics.indexWhere((t) => t.id == finalTopic.id);
    if (cachedIdx >= 0) {
      _cachedKanjiTopics[cachedIdx] = finalTopic;
    } else {
      _cachedKanjiTopics.add(finalTopic);
    }
    await _persistLocalKanjiTopics();
    _sortCachedKanjiTopics();
    notifyListeners();
  }

  Future<void> saveKanjiTopicsBatch(List<KanjiTopicModel> topicsList) async {
    _assertAdminAuthenticated('saveKanjiTopicsBatch');
    if (topicsList.isEmpty) return;

    if (useFirebase && _db != null) {
      final batch = _db.batch();
      for (final topic in topicsList) {
        final docRef = _db.collection('kanji_topics').doc(topic.id);
        batch.set(docRef, topic.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    }

    for (final topic in topicsList) {
      final index = _cachedKanjiTopics.indexWhere((t) => t.id == topic.id);
      if (index >= 0) {
        _cachedKanjiTopics[index] = topic;
      } else {
        _cachedKanjiTopics.add(topic);
      }
    }

    _sortCachedKanjiTopics();
    await _persistLocalKanjiTopics();
    notifyListeners();
  }

  Future<void> updateKanjiTopicTitle(String topicId, String newTitle) async {
    _assertAdminAuthenticated('updateKanjiTopicTitle');
    final index = _cachedKanjiTopics.indexWhere((t) => t.id == topicId);
    if (index >= 0) {
      final old = _cachedKanjiTopics[index];
      _cachedKanjiTopics[index] = KanjiTopicModel(
        id: old.id,
        title: newTitle,
        jlpt: old.jlpt,
        section: old.section,
        tags: old.tags,
        kanji: old.kanji,
        metadata: old.metadata,
      );
      _sortCachedKanjiTopics();
      await _persistLocalKanjiTopics();
      if (useFirebase && _db != null) {
        try {
          await _db.collection('kanji_topics').doc(topicId).update({'title': newTitle});
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> deleteKanjiTopic(String topicId) async {
    _assertAdminAuthenticated('deleteKanjiTopic');
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

  // ================= 40% PREMIUM LOCK HELPERS (60% Free) =================

  bool isGrammarTopicLocked(String topicId, bool isPremium, {bool isAdmin = false}) {
    if (isPremium || isAdmin) return false;
    final topic = getTopicById(topicId);
    if (topic == null) return false;
    final list = getTopicsForLevel(topic.jlpt);
    final freeCount = (list.length * 0.6).ceil();
    final index = list.indexWhere((t) => t.id == topicId);
    return index >= freeCount;
  }

  bool isVocabTopicLocked(String topicId, bool isPremium, {bool isAdmin = false}) {
    if (isPremium || isAdmin) return false;
    final topic = getVocabTopicById(topicId);
    if (topic == null) return false;
    final list = getVocabTopicsForLevel(topic.jlpt);
    final freeCount = (list.length * 0.6).ceil();
    final index = list.indexWhere((t) => t.id == topicId);
    return index >= freeCount;
  }

  bool isKanjiTopicLocked(String topicId, bool isPremium, {bool isAdmin = false}) {
    if (isPremium || isAdmin) return false;
    final topic = getKanjiTopicById(topicId);
    if (topic == null) return false;
    final list = getKanjiTopicsForLevel(topic.jlpt);
    final freeCount = (list.length * 0.6).ceil();
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

  // --- UNIFIED MULTI-CATEGORY QUESTIONS (Grammar, Vocab, Kanji) ---

  List<UnifiedReviewQuestion> getUnifiedQuestions({
    String? level,
    String category = 'grammar',
    String? topicId,
  }) {
    final List<UnifiedReviewQuestion> list = [];
    final lvl = (level != null && level.toUpperCase() != 'ALL') ? level.toUpperCase() : null;

    if (category == 'vocab') {
      final topics = topicId != null
          ? _cachedVocabTopics.where((t) => t.id == topicId).toList()
          : (lvl != null ? getVocabTopicsForLevel(lvl) : _cachedVocabTopics);
      for (final t in topics) {
        for (final item in t.vocabulary) {
          for (final q in item.questions) {
            list.add(UnifiedReviewQuestion(
              id: q.id,
              category: 'vocab',
              topicId: t.id,
              topicTitle: t.title,
              jlpt: t.jlpt,
              japanese: q.japanese.isNotEmpty ? q.japanese : item.word,
              english: q.english.isNotEmpty ? q.english : item.meaning,
              questionText: q.question,
              options: q.options,
              correctOption: q.correctOption,
              completedSentence: q.completedSentence,
              explanation: q.explanation.correct,
              wrongExplanations: q.explanation.wrong,
              badgeText: '単語: ${item.word} 【${item.reading}】',
            ));
          }
        }
      }
    } else if (category == 'kanji') {
      final topics = topicId != null
          ? _cachedKanjiTopics.where((t) => t.id == topicId).toList()
          : (lvl != null ? getKanjiTopicsForLevel(lvl) : _cachedKanjiTopics);
      for (final t in topics) {
        for (final item in t.kanji) {
          for (final q in item.questions) {
            list.add(UnifiedReviewQuestion(
              id: q.id,
              category: 'kanji',
              topicId: t.id,
              topicTitle: t.title,
              jlpt: t.jlpt,
              japanese: q.japanese.isNotEmpty ? q.japanese : item.character,
              english: q.english.isNotEmpty ? q.english : item.meanings.join(', '),
              questionText: q.question,
              options: q.options,
              correctOption: q.correctOption,
              completedSentence: q.completedSentence,
              explanation: q.explanation.correct,
              wrongExplanations: q.explanation.wrong,
              badgeText: '漢字: ${item.character} (${item.meanings.take(2).join(', ')})',
            ));
          }
        }
      }
    } else {
      // Default: grammar
      final topics = topicId != null
          ? _cachedTopics.where((t) => t.id == topicId).toList()
          : (lvl != null ? getTopicsForLevel(lvl) : _cachedTopics);
      for (final t in topics) {
        for (final q in t.questions) {
          list.add(UnifiedReviewQuestion(
            id: q.id,
            category: 'grammar',
            topicId: t.id,
            topicTitle: t.title,
            jlpt: t.jlpt,
            japanese: q.japanese,
            english: q.english,
            options: q.getEffectiveOptions(t.globalOptions),
            correctOption: q.correctOption,
            completedSentence: q.completedSentence,
            explanation: q.explanation.correct,
            wrongExplanations: q.explanation.wrong,
            badgeText: t.title,
          ));
        }
      }
    }
    return list;
  }

  List<UnifiedReviewQuestion> getDueUnifiedQuestions({String? level, String category = 'grammar'}) {
    final all = getUnifiedQuestions(level: level, category: category);
    final List<UnifiedReviewQuestion> due = [];
    for (final q in all) {
      final progress = getQuestionProgress(q.id);
      if (progress == null || progress.isDue) {
        due.add(q);
      }
    }
    return due;
  }

  List<UnifiedReviewQuestion> getDifficultUnifiedQuestions({String? level, String category = 'grammar'}) {
    final all = getUnifiedQuestions(level: level, category: category);
    final List<UnifiedReviewQuestion> list = [];
    for (final q in all) {
      final progress = getQuestionProgress(q.id);
      if (progress != null && progress.isDifficult) {
        list.add(q);
      }
    }
    return list;
  }

  List<UnifiedReviewQuestion> getEasyUnifiedQuestions({String? level, String category = 'grammar'}) {
    final all = getUnifiedQuestions(level: level, category: category);
    final List<UnifiedReviewQuestion> list = [];
    for (final q in all) {
      final progress = getQuestionProgress(q.id);
      if (progress != null && progress.isMasteredEasy) {
        list.add(q);
      }
    }
    return list;
  }

  List<UnifiedReviewQuestion> generateUnifiedRandomTest({
    String? level,
    String category = 'grammar',
    int? count,
    bool difficultOnly = false,
  }) {
    List<UnifiedReviewQuestion> pool = difficultOnly
        ? getDifficultUnifiedQuestions(level: level, category: category)
        : getUnifiedQuestions(level: level, category: category);

    pool.shuffle();
    if (count != null && count > 0 && pool.length > count) {
      return pool.take(count).toList();
    }
    return pool;
  }

  int getCategorySrsDueCount(String category, {String? level}) {
    return getDueUnifiedQuestions(level: level, category: category).length;
  }

  int getCategoryDifficultCount(String category, {String? level}) {
    return getDifficultUnifiedQuestions(level: level, category: category).length;
  }

  int getCategoryDifficultDueCount(String category, {String? level}) {
    final diff = getDifficultUnifiedQuestions(level: level, category: category);
    final due = diff.where((q) {
      final p = getQuestionProgress(q.id);
      return p == null || p.isDue;
    }).length;
    return due > 0 ? due : diff.length;
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

  Future<void> recordQuestionAttempt(dynamic questionId, bool isCorrect, {String? category}) async {
    String topicId = '';
    String jlpt = 'N3';

    // 1. Search Grammar
    for (final t in _cachedTopics) {
      if (t.questions.any((q) => q.id.toString() == questionId.toString())) {
        topicId = t.id;
        jlpt = t.jlpt;
        break;
      }
    }

    // 2. Search Vocab
    if (topicId.isEmpty) {
      for (final t in _cachedVocabTopics) {
        for (final item in t.vocabulary) {
          if (item.questions.any((q) => q.id.toString() == questionId.toString())) {
            topicId = t.id;
            jlpt = t.jlpt;
            break;
          }
        }
        if (topicId.isNotEmpty) break;
      }
    }

    // 3. Search Kanji
    if (topicId.isEmpty) {
      for (final t in _cachedKanjiTopics) {
        for (final item in t.kanji) {
          if (item.questions.any((q) => q.id.toString() == questionId.toString())) {
            topicId = t.id;
            jlpt = t.jlpt;
            break;
          }
        }
        if (topicId.isNotEmpty) break;
      }
    }

    final key = questionId.toString();
    final existing = _cachedSrsProgress[key] ??
        SrsProgressModel(
          id: 'srs_$questionId',
          userId: 'current_user',
          topicId: topicId.isNotEmpty ? topicId : 'topic_$questionId',
          questionId: questionId is int ? questionId : (int.tryParse(questionId.toString()) ?? 0),
          jlpt: jlpt,
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

  // ================= ADMIN QUESTION EDITOR =================

  Future<bool> updateQuestionContent({
    required String category,
    required dynamic questionId,
    required String newJapanese,
    required String newCompletedSentence,
    required Map<String, String> newOptions,
    required String newCorrectOption,
    String? newExplanation,
  }) async {
    _assertAdminAuthenticated('updateQuestionContent');
    bool updated = false;
    final qIdStr = questionId.toString();

    // 1. Check Grammar
    if (category.toLowerCase() == 'grammar') {
      for (int tIdx = 0; tIdx < _cachedTopics.length; tIdx++) {
        final topic = _cachedTopics[tIdx];
        final qIdx = topic.questions.indexWhere((q) => q.id.toString() == qIdStr);
        if (qIdx >= 0) {
          final oldQ = topic.questions[qIdx];
          final updatedQ = GrammarQuestion(
            id: oldQ.id,
            grammarId: oldQ.grammarId,
            japanese: newJapanese.isNotEmpty ? newJapanese : oldQ.japanese,
            english: oldQ.english,
            completedSentence: newCompletedSentence.isNotEmpty ? newCompletedSentence : oldQ.completedSentence,
            options: newOptions,
            correctOption: newCorrectOption,
            explanation: oldQ.explanation,
          );
          final updatedQuestions = List<GrammarQuestion>.from(topic.questions);
          updatedQuestions[qIdx] = updatedQ;

          final updatedTopic = GrammarTopicModel(
            id: topic.id,
            title: topic.title,
            jlpt: topic.jlpt,
            section: topic.section,
            category: topic.category,
            tags: topic.tags,
            description: topic.description,
            grammarPoints: topic.grammarPoints,
            globalOptions: topic.globalOptions,
            instructions: topic.instructions,
            questions: updatedQuestions,
            metadata: topic.metadata,
          );
          _cachedTopics[tIdx] = updatedTopic;
          await _persistLocalTopics();
          if (useFirebase && _db != null) {
            try {
              await _db.collection('grammar_topics').doc(topic.id).set(updatedTopic.toMap(), SetOptions(merge: true));
            } catch (_) {}
          }
          updated = true;
          break;
        }
      }
    }

    // 2. Check Vocabulary
    if (category.toLowerCase() == 'vocab' || !updated) {
      for (int tIdx = 0; tIdx < _cachedVocabTopics.length; tIdx++) {
        final topic = _cachedVocabTopics[tIdx];
        bool topicChanged = false;
        final updatedVocabItems = <VocabularyItem>[];

        for (final item in topic.vocabulary) {
          final qIdx = item.questions.indexWhere((q) => q.id.toString() == qIdStr);
          if (qIdx >= 0) {
            final oldQ = item.questions[qIdx];
            final updatedQ = VocabularyQuestion(
              id: oldQ.id,
              type: oldQ.type,
              question: oldQ.question,
              japanese: newJapanese.isNotEmpty ? newJapanese : oldQ.japanese,
              completedSentence: newCompletedSentence.isNotEmpty ? newCompletedSentence : oldQ.completedSentence,
              options: newOptions,
              correctOption: newCorrectOption,
              explanation: oldQ.explanation,
            );
            final updatedQuestions = List<VocabularyQuestion>.from(item.questions);
            updatedQuestions[qIdx] = updatedQ;

            updatedVocabItems.add(VocabularyItem(
              id: item.id,
              word: item.word,
              reading: item.reading,
              meaning: item.meaning,
              partOfSpeech: item.partOfSpeech,
              explanation: item.explanation,
              commonCollocations: item.commonCollocations,
              questions: updatedQuestions,
            ));
            topicChanged = true;
          } else {
            updatedVocabItems.add(item);
          }
        }

        if (topicChanged) {
          final updatedTopic = VocabularyTopicModel(
            id: topic.id,
            title: topic.title,
            jlpt: topic.jlpt,
            section: topic.section,
            tags: topic.tags,
            vocabulary: updatedVocabItems,
            metadata: topic.metadata,
          );
          _cachedVocabTopics[tIdx] = updatedTopic;
          await _persistLocalVocabTopics();
          if (useFirebase && _db != null) {
            try {
              await _db.collection('vocabulary_topics').doc(topic.id).set(updatedTopic.toMap(), SetOptions(merge: true));
            } catch (_) {}
          }
          updated = true;
          break;
        }
      }
    }

    // 3. Check Kanji
    if (category.toLowerCase() == 'kanji' || !updated) {
      for (int tIdx = 0; tIdx < _cachedKanjiTopics.length; tIdx++) {
        final topic = _cachedKanjiTopics[tIdx];
        bool topicChanged = false;
        final updatedKanjiItems = <KanjiItem>[];

        for (final item in topic.kanji) {
          final qIdx = item.questions.indexWhere((q) => q.id.toString() == qIdStr);
          if (qIdx >= 0) {
            final oldQ = item.questions[qIdx];
            final updatedQ = KanjiQuestion(
              id: oldQ.id,
              type: oldQ.type,
              question: oldQ.question,
              japanese: newJapanese.isNotEmpty ? newJapanese : oldQ.japanese,
              completedSentence: newCompletedSentence.isNotEmpty ? newCompletedSentence : oldQ.completedSentence,
              options: newOptions,
              correctOption: newCorrectOption,
              explanation: oldQ.explanation,
            );
            final updatedQuestions = List<KanjiQuestion>.from(item.questions);
            updatedQuestions[qIdx] = updatedQ;

            updatedKanjiItems.add(KanjiItem(
              id: item.id,
              character: item.character,
              meanings: item.meanings,
              onyomi: item.onyomi,
              kunyomi: item.kunyomi,
              strokeCount: item.strokeCount,
              explanation: item.explanation,
              commonWords: item.commonWords,
              questions: updatedQuestions,
            ));
            topicChanged = true;
          } else {
            updatedKanjiItems.add(item);
          }
        }

        if (topicChanged) {
          final updatedTopic = KanjiTopicModel(
            id: topic.id,
            title: topic.title,
            jlpt: topic.jlpt,
            section: topic.section,
            tags: topic.tags,
            kanji: updatedKanjiItems,
            metadata: topic.metadata,
          );
          _cachedKanjiTopics[tIdx] = updatedTopic;
          await _persistLocalKanjiTopics();
          if (useFirebase && _db != null) {
            try {
              await _db.collection('kanji_topics').doc(topic.id).set(updatedTopic.toMap(), SetOptions(merge: true));
            } catch (_) {}
          }
          updated = true;
          break;
        }
      }
    }

    // Automatically resolve associated reports
    for (final r in _cachedReports.where((r) => r.questionId.toString() == qIdStr && r.status == 'pending')) {
      await updateReportStatus(r.id, 'resolved');
    }

    notifyListeners();
    return updated;
  }
}
