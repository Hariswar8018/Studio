import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsEvent {
  final String eventId;
  final String eventName;
  final DateTime timestamp;
  final String userId;
  final String sessionId;
  final Map<String, dynamic> parameters;

  AnalyticsEvent({
    required this.eventId,
    required this.eventName,
    required this.timestamp,
    required this.userId,
    required this.sessionId,
    required this.parameters,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
      'parameters': parameters,
    };
  }

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) {
    return AnalyticsEvent(
      eventId: map['eventId']?.toString() ?? '',
      eventName: map['eventName']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      userId: map['userId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
    );
  }
}

class AnalyticsService extends ChangeNotifier {
  final bool useFirebase;
  final FirebaseFirestore? _db;
  final FirebaseAnalytics? _firebaseAnalytics;
  final FirebaseAnalyticsObserver? _observer;
  late final String _sessionId;
  static const String _eventsStorageKey = 'jlpt_grammar_cached_analytics_events';
  static const int _maxCachedEvents = 500;

  final List<AnalyticsEvent> _recentEvents = [];

  AnalyticsService({required this.useFirebase})
      : _db = useFirebase ? FirebaseFirestore.instance : null,
        _firebaseAnalytics = useFirebase ? FirebaseAnalytics.instance : null,
        _observer = (useFirebase && !kDebugMode)
            ? FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)
            : null {
    _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
    _loadCachedEvents();
    if (useFirebase && _firebaseAnalytics != null) {
      _initFirebaseAnalytics();
    }
  }

  Future<void> _initFirebaseAnalytics() async {
    try {
      final fa = _firebaseAnalytics;
      if (fa != null) {
        if (kDebugMode) {
          // Strictly disable collection in debug app
          await fa.setAnalyticsCollectionEnabled(false);
          debugPrint("📊 [Firebase Analytics] Collection strictly DISABLED in DEBUG mode.");
          return;
        }
        await fa.setAnalyticsCollectionEnabled(true);
        await fa.logAppOpen();
        debugPrint("📊 [Firebase Analytics] Collection enabled & app_open event sent in release mode.");
      }
    } catch (e) {
      debugPrint("❌ [Firebase Analytics] Init notice: $e");
    }
  }

  FirebaseAnalytics? get firebaseAnalytics => _firebaseAnalytics;
  FirebaseAnalyticsObserver? get observer => _observer;
  List<AnalyticsEvent> get recentEvents => List.unmodifiable(_recentEvents);
  String get sessionId => _sessionId;

  Future<void> _loadCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_eventsStorageKey) ?? [];
      _recentEvents.clear();
      for (final raw in rawList) {
        try {
          final map = json.decode(raw);
          _recentEvents.add(AnalyticsEvent.fromMap(map));
        } catch (_) {}
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading cached analytics: $e");
    }
  }

  Future<void> _persistEventLocally(AnalyticsEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentEvents.insert(0, event);
      if (_recentEvents.length > _maxCachedEvents) {
        _recentEvents.removeRange(_maxCachedEvents, _recentEvents.length);
      }
      final rawList = _recentEvents.map((e) => json.encode(e.toMap())).toList();
      await prefs.setStringList(_eventsStorageKey, rawList);
    } catch (e) {
      debugPrint("Error persisting local analytics event: $e");
    }
  }

  String _sanitizeEventName(String name) {
    String sanitized = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (sanitized.length > 40) {
      sanitized = sanitized.substring(0, 40);
    }
    return sanitized;
  }

  Map<String, Object>? _sanitizeParameters(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return null;
    final Map<String, Object> result = {};
    params.forEach((key, value) {
      final sanitizedKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      if (value is String || value is num) {
        result[sanitizedKey] = value;
      } else if (value is bool) {
        result[sanitizedKey] = value ? 1 : 0;
      } else if (value != null) {
        result[sanitizedKey] = value.toString();
      }
    });
    return result;
  }

  /// Core logging method: records to local buffer, Firestore, and Google Firebase Analytics
  /// Does NOT send anything in debug mode!
  Future<void> logEvent(
    String eventName, {
    String? userId,
    Map<String, dynamic>? parameters,
  }) async {
    // In debug mode, analytics should not exist/fire remotely
    if (kDebugMode) {
      debugPrint("🛠️ [Debug Analytics - Suppressed] '$eventName' params: $parameters");
      return;
    }

    final event = AnalyticsEvent(
      eventId: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      eventName: eventName,
      timestamp: DateTime.now(),
      userId: userId ?? 'guest',
      sessionId: _sessionId,
      parameters: parameters ?? {},
    );

    // 1. Persist in local buffer
    await _persistEventLocally(event);

    // 2. Upload to Firestore collection 'analytics_events'
    if (useFirebase && _db != null) {
      try {
        await _db.collection('analytics_events').doc(event.eventId).set(event.toMap());
      } catch (e) {
        debugPrint("Firestore analytics upload failed: $e");
      }
    }

    // 3. Send to Google Firebase Analytics
    final fa = _firebaseAnalytics;
    if (useFirebase && fa != null) {
      try {
        final sanitizedName = _sanitizeEventName(eventName);
        final sanitizedParams = _sanitizeParameters(parameters);
        await fa.logEvent(
          name: sanitizedName,
          parameters: sanitizedParams,
        );
      } catch (e) {
        debugPrint("❌ [Firebase Analytics] logEvent error: $e");
      }
    }
  }

  Future<void> setUserId(String? userId) async {
    if (kDebugMode) return;
    final fa = _firebaseAnalytics;
    if (useFirebase && fa != null) {
      try {
        await fa.setUserId(id: userId);
      } catch (e) {
        debugPrint("Firebase Analytics setUserId error: $e");
      }
    }
  }

  Future<void> setUserProperty({required String name, required String? value}) async {
    if (kDebugMode) return;
    final fa = _firebaseAnalytics;
    if (useFirebase && fa != null) {
      try {
        await fa.setUserProperty(name: name, value: value);
      } catch (e) {
        debugPrint("Firebase Analytics setUserProperty error: $e");
      }
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    if (kDebugMode) return;
    final fa = _firebaseAnalytics;
    if (useFirebase && fa != null) {
      try {
        await fa.logScreenView(
          screenName: screenName,
          screenClass: screenClass ?? screenName,
          parameters: parameters != null ? Map<String, Object>.from(parameters) : null,
        );
      } catch (e) {
        debugPrint("Firebase Analytics logScreenView error: $e");
      }
    }
    final mergedParams = <String, dynamic>{'screen_name': screenName};
    if (parameters != null) {
      mergedParams.addAll(parameters);
    }
    await logEvent('screen_view', parameters: mergedParams);
  }

  // --- Common High-level Learning Events ---

  Future<void> logLessonStarted({
    required String lessonId,
    required String level,
    required String category,
    String? title,
    String? userId,
  }) async {
    await logEvent('lesson_started', userId: userId, parameters: {
      'lessonId': lessonId,
      'level': level,
      'category': category,
      'title': title ?? '',
    });
  }

  Future<void> logLessonCompleted({
    required String lessonId,
    required String level,
    required String category,
    required int score,
    required int totalQuestions,
    int? durationSeconds,
    String? title,
    String? userId,
  }) async {
    final double accuracy = totalQuestions > 0 ? (score / totalQuestions) : 0.0;
    await logEvent('lesson_completed', userId: userId, parameters: {
      'lessonId': lessonId,
      'level': level,
      'category': category,
      'title': title ?? '',
      'score': score,
      'totalQuestions': totalQuestions,
      'durationSeconds': durationSeconds ?? 0,
      'accuracyRate': double.parse(accuracy.toStringAsFixed(2)),
    });
  }

  Future<void> logQuestionAnswered({
    required String lessonId,
    required String category,
    int? questionIndex,
    dynamic questionId,
    required bool isCorrect,
    String? selectedOption,
    String? correctOption,
    String? userId,
  }) async {
    await logEvent('question_answered', userId: userId, parameters: {
      'lessonId': lessonId,
      'category': category,
      'questionIndex': questionIndex ?? 0,
      'questionId': questionId?.toString() ?? '',
      'isCorrect': isCorrect,
      'selectedOption': selectedOption ?? '',
      'correctOption': correctOption ?? '',
    });
  }

  Future<void> logLevelSelected({required String level, String? userId}) async {
    await logEvent('level_selected', userId: userId, parameters: {'level': level});
    await setUserProperty(name: 'selected_level', value: level);
  }

  Future<void> logCategorySelected({required String category, String? userId}) async {
    await logEvent('category_selected', userId: userId, parameters: {'category': category});
    await setUserProperty(name: 'selected_category', value: category);
  }

  Future<void> logAudioPlayed({
    required String text,
    required String category,
    String? screen,
    String? userId,
  }) async {
    await logEvent('audio_played', userId: userId, parameters: {
      'text': text.length > 50 ? text.substring(0, 50) : text,
      'category': category,
      'screen': screen ?? '',
    });
  }

  Future<void> logKanjiCanvasUsed({
    required String character,
    required String mode, // 'draw' or 'animation'
    String? userId,
  }) async {
    await logEvent('kanji_canvas_used', userId: userId, parameters: {
      'character': character,
      'mode': mode,
    });
  }

  Future<void> logSrsReviewStarted({
    required String category,
    required int dueCount,
    String? level,
    String? userId,
  }) async {
    await logEvent('srs_review_started', userId: userId, parameters: {
      'category': category,
      'dueCount': dueCount,
      'level': level ?? '',
    });
  }

  Future<void> logSrsReviewCompleted({
    required String category,
    required int correctCount,
    required int totalCount,
    String? userId,
  }) async {
    await logEvent('srs_review_completed', userId: userId, parameters: {
      'category': category,
      'correctCount': correctCount,
      'totalCount': totalCount,
    });
  }

  Future<void> logQuestionReported({
    required dynamic questionId,
    required String topicId,
    required String category,
    required String reason,
    String? userId,
  }) async {
    await logEvent('question_reported', userId: userId, parameters: {
      'questionId': questionId.toString(),
      'topicId': topicId,
      'category': category,
      'reason': reason,
    });
  }

  Future<void> logPaywallViewed({
    required String source,
    String? userId,
  }) async {
    await logEvent('paywall_viewed', userId: userId, parameters: {
      'source': source,
    });
  }

  Future<void> logSubscriptionPurchased({
    required String planId,
    String? userId,
  }) async {
    await logEvent('subscription_purchased', userId: userId, parameters: {
      'planId': planId,
    });
  }

  Future<void> logAdImpression({
    required String adType, // 'native', 'interstitial'
    String? placement,
    String? userId,
  }) async {
    await logEvent('ad_impression', userId: userId, parameters: {
      'adType': adType,
      'placement': placement ?? '',
    });
  }
}

