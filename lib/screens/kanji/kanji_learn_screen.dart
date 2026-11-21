import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kanjivg/flutter_kanjivg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/kanji_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/kanji_service.dart';
import '../../services/theme_service.dart';
import '../../services/tts_service.dart';
import '../../services/ad_service.dart';
import '../../services/analytics_service.dart';
import '../../services/iap_service.dart';
import '../../widgets/grammar_japanese_sentence_widget.dart';
import '../../widgets/app_native_ad_widget.dart';
import '../../widgets/clipboard_helper.dart';
import '../../widgets/question_report_dialog.dart';
import '../../widgets/premium_subscription_dialog.dart';

class KanjiLearnScreen extends StatefulWidget {
  final KanjiTopicModel topic;

  const KanjiLearnScreen({super.key, required this.topic});

  @override
  State<KanjiLearnScreen> createState() => _KanjiLearnScreenState();
}

class _KanjiLearnScreenState extends State<KanjiLearnScreen> with TickerProviderStateMixin {
  bool _inPracticeMode = false;
  int _selectedKanjiIndex = 0;

  // Drawing & Tracing State
  int _canvasMode = 0; // 0: Freehand Trace/Draw, 1: Animated Stroke Order
  final List<List<Offset>> _userStrokes = [];
  List<Offset>? _currentStroke;

  // KanjiVG Stroke Animation Controller
  late final KanjiController _kanjiController;
  KvgData? _currentKvgData;
  bool _isLoadingKvg = false;
  int _speedMultiplier = 1;
  int _currentStrokeStep = 0;

  // Practice state
  bool _isFullPracticeTest = false;
  late List<KanjiQuestion> _currentQuestions;
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _isAnswerSubmitted = false;
  int _correctCount = 0;

  int get _totalQuestionsInTopic {
    return widget.topic.kanji.fold<int>(0, (sum, item) => sum + item.questions.length);
  }

  @override
  void initState() {
    super.initState();
    _kanjiController = KanjiController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _kanjiController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCurrentKanji();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logLessonStarted(
          lessonId: widget.topic.id,
          level: widget.topic.jlpt,
          category: 'kanji',
          title: widget.topic.title,
        );
      }
    });
  }

  @override
  void dispose() {
    _kanjiController.dispose();
    super.dispose();
  }

  void _loadCurrentKanji() {
    if (widget.topic.kanji.isNotEmpty) {
      final kanji = widget.topic.kanji[_selectedKanjiIndex];
      _currentQuestions = List<KanjiQuestion>.from(kanji.questions)..shuffle();
      _userStrokes.clear();
      _currentStrokeStep = 0;
      _loadKvgData(kanji.character);
    } else {
      _currentQuestions = [];
    }
  }

  Future<bool> _handlePracticeBack() async {
    if (!_inPracticeMode || _currentQuestionIndex >= _currentQuestions.length) {
      return true;
    }

    final db = Provider.of<DatabaseService>(context, listen: false);

    // If user answered at least 3 questions in full test, mark lesson as complete so it adds to SRS review
    if (_currentQuestionIndex >= 2 || _correctCount >= 3) {
      await db.markKanjiCompleted(widget.topic.id);
    }

    // Save current progress before asking
    await db.savePracticeProgress(
      topicId: widget.topic.id,
      category: 'kanji',
      currentIndex: _currentQuestionIndex,
      correctCount: _correctCount,
      questionIds: _currentQuestions.map((q) => q.id).toList(),
      isFullPractice: _isFullPracticeTest,
    );

    if (!mounted) return false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.pause_circle_filled_rounded, color: Color(0xFF8B5CF6), size: 26),
            const SizedBox(width: 10),
            Text(
              'Pause Practice?',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Your progress on Question ${_currentQuestionIndex + 1} of ${_currentQuestions.length} has been saved.\n\n${(_currentQuestionIndex >= 2 || _correctCount >= 3) ? "✅ Lesson marked completed (3+ questions answered) and added to SRS review!\n\n" : ""}Would you like to exit to study mode or keep practicing?',
          style: GoogleFonts.fredoka(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Resume Practice', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Save & Exit', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      setState(() => _inPracticeMode = false);
      return false;
    }
    return false;
  }

  Future<void> _checkAndStartFullPractice() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final saved = await db.getPracticeProgress(widget.topic.id);

    if (saved != null && saved.currentIndex > 0 && saved.currentIndex < _totalQuestionsInTopic) {
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF8B5CF6), size: 26),
              const SizedBox(width: 10),
              Text(
                'Resume Practice?',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'You previously stopped at Question ${saved.currentIndex + 1} of ${saved.questionIds.length} (${saved.correctCount} correct).\n\nWould you like to continue from where you left off or start a full random test?',
            style: GoogleFonts.fredoka(fontSize: 14),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, 'fresh'),
              child: Text('Start Fresh (Random)', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, 'resume'),
              child: Text('Resume (Q ${saved.currentIndex + 1})', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (choice == 'resume') {
        final allQ = <KanjiQuestion>[];
        for (final k in widget.topic.kanji) {
          allQ.addAll(k.questions);
        }
        final qMap = {for (var q in allQ) q.id.toString(): q};
        final orderedQuestions = <KanjiQuestion>[];
        for (var id in saved.questionIds) {
          if (qMap.containsKey(id)) {
            orderedQuestions.add(qMap[id]!);
          }
        }
        for (var q in allQ) {
          if (!orderedQuestions.contains(q)) {
            orderedQuestions.add(q);
          }
        }

        setState(() {
          _isFullPracticeTest = saved.isFullPractice;
          _currentQuestions = orderedQuestions;
          _currentQuestionIndex = saved.currentIndex.clamp(0, orderedQuestions.length - 1);
          _correctCount = saved.correctCount;
          _selectedOption = null;
          _isAnswerSubmitted = false;
          _inPracticeMode = true;
        });
        return;
      } else if (choice == 'fresh') {
        await db.clearPracticeProgress(widget.topic.id);
      } else {
        return;
      }
    }

    _startFullPracticeTest();
  }

  void _startFullPracticeTest() {
    final allQuestions = <KanjiQuestion>[];
    for (final kanji in widget.topic.kanji) {
      allQuestions.addAll(kanji.questions);
    }
    allQuestions.shuffle();
    setState(() {
      _isFullPracticeTest = true;
      _currentQuestions = allQuestions;
      _inPracticeMode = true;
      _currentQuestionIndex = 0;
      _selectedOption = null;
      _isAnswerSubmitted = false;
      _correctCount = 0;
    });
  }

  Future<void> _loadKvgData(String char) async {
    if (char.isEmpty) return;
    setState(() => _isLoadingKvg = true);
    try {
      final targetChar = char.characters.isNotEmpty ? char.characters.first : char;
      final data = await KanjiService.instance.getKanjiData(targetChar);
      if (mounted) {
        setState(() {
          _currentKvgData = data;
          _isLoadingKvg = false;
        });
        if (data != null) {
          _kanjiController.duration = Duration(milliseconds: (3500 ~/ _speedMultiplier));
          _kanjiController.load(data);
          _kanjiController.forward();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingKvg = false);
    }
  }

  void _stepNextStroke() {
    if (_currentKvgData == null) return;
    final total = _currentKvgData!.strokes;
    if (_currentStrokeStep < total) {
      _currentStrokeStep++;
      _kanjiController.drawTo(_currentStrokeStep);
    }
  }

  void _stepPreviousStroke() {
    if (_currentKvgData == null) return;
    if (_currentStrokeStep > 0) {
      _currentStrokeStep--;
      if (_currentStrokeStep == 0) {
        _kanjiController.reset();
      } else {
        _kanjiController.drawTo(_currentStrokeStep);
      }
    }
  }

  void _startPracticeForKanji(int index) {
    setState(() {
      _isFullPracticeTest = false;
      _selectedKanjiIndex = index;
      _loadCurrentKanji();
      _inPracticeMode = true;
      _currentQuestionIndex = 0;
      _selectedOption = null;
      _isAnswerSubmitted = false;
      _correctCount = 0;
    });
  }

  void _submitAnswer(String optionKey) {
    if (_isAnswerSubmitted || _currentQuestions.isEmpty) return;

    final question = _currentQuestions[_currentQuestionIndex];
    final isCorrect = (optionKey == question.correctOption);

    setState(() {
      _selectedOption = optionKey;
      _isAnswerSubmitted = true;
      if (isCorrect) _correctCount++;
    });

    // Log Question Answered Analytics
    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      analytics.logQuestionAnswered(
        lessonId: widget.topic.id,
        category: 'kanji',
        questionIndex: _currentQuestionIndex,
        questionId: question.id,
        isCorrect: isCorrect,
        selectedOption: optionKey,
        correctOption: question.correctOption,
      );
    } catch (_) {}

    // Save progress after answering
    final db = Provider.of<DatabaseService>(context, listen: false);
    db.savePracticeProgress(
      topicId: widget.topic.id,
      category: 'kanji',
      currentIndex: _currentQuestionIndex,
      correctCount: _correctCount,
      questionIds: _currentQuestions.map((q) => q.id).toList(),
      isFullPractice: _isFullPracticeTest,
    );

    // If user answered at least 3 questions in full practice test, mark Lesson as Complete so it adds to SRS review
    if (_isFullPracticeTest && (_currentQuestionIndex >= 2 || _correctCount >= 3)) {
      db.markKanjiCompleted(widget.topic.id);
    }

    // Speak full sentence audio on correct or wrong
    try {
      final tts = Provider.of<TtsService>(context, listen: false);
      String audioText = question.completedSentence.isNotEmpty
          ? question.completedSentence
          : (question.japanese.isNotEmpty
              ? question.japanese
              : widget.topic.kanji[_selectedKanjiIndex].character);
      if (audioText.contains('___')) {
        final fill = question.options[question.correctOption] ?? '';
        audioText = audioText.replaceAll('___', fill);
      }
      tts.speak(audioText);
    } catch (e) {
      debugPrint('TTS playback error: $e');
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex + 1 < _currentQuestions.length) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswerSubmitted = false;
      });
    } else {
      setState(() {
        _currentQuestionIndex++; // Points to completed
      });

      // Mark Kanji as completed & clear in-progress state
      final db = Provider.of<DatabaseService>(context, listen: false);
      db.markKanjiCompleted(widget.topic.id);
      db.clearPracticeProgress(widget.topic.id);

      // Log Lesson Completed Analytics
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logLessonCompleted(
          lessonId: widget.topic.id,
          level: widget.topic.jlpt,
          category: 'kanji',
          score: _correctCount,
          totalQuestions: _currentQuestions.length,
          title: widget.topic.title,
        );
      } catch (_) {}

      // Trigger interstitial ad
      final adService = Provider.of<AdService>(context, listen: false);
      final iap = Provider.of<IapService>(context, listen: false);
      adService.showInterstitialAdIfNeeded(isPremium: iap.isPremium);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final tts = Provider.of<TtsService>(context);
    final db = Provider.of<DatabaseService>(context);
    final iap = Provider.of<IapService>(context);
    final auth = Provider.of<AuthService>(context);
    final isDark = theme.isDarkMode;
    final isAdmin = auth.isAdmin;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final isLocked = db.isKanjiTopicLocked(widget.topic.id, iap.isPremium, isAdmin: isAdmin);

    return PopScope(
      canPop: !_inPracticeMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _inPracticeMode) {
          _handlePracticeBack();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
            onPressed: () {
              if (_inPracticeMode) {
                _handlePracticeBack();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        title: Text(
          _inPracticeMode
              ? (_isFullPracticeTest
                  ? 'Full Practice (${_currentQuestions.length} Qs)'
                  : 'Kanji Practice: ${widget.topic.kanji.isNotEmpty ? widget.topic.kanji[_selectedKanjiIndex].character : ""}')
              : widget.topic.title,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: theme.showFurigana ? 'Furigana/Romaji: ON' : 'Furigana/Romaji: OFF',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.showFurigana ? const Color(0xFF6366F1) : (isDark ? Colors.white12 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ふ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.showFurigana ? Colors.white : subtextColor,
                ),
              ),
            ),
            onPressed: () => theme.toggleFurigana(),
          ),
          IconButton(
            tooltip: theme.isVibrantText ? 'Colorful Words: ON' : 'Colorful Words: OFF',
            icon: Icon(
              Icons.palette_rounded,
              color: theme.isVibrantText ? const Color(0xFFEC4899) : subtextColor,
              size: 20,
            ),
            onPressed: () => theme.toggleVibrantText(),
          ),
          if (!_inPracticeMode && _totalQuestionsInTopic > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 17),
                label: Text('Full Test ($_totalQuestionsInTopic Qs)', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _checkAndStartFullPractice,
              ),
            ),
        ],
      ),
      body: isLocked
          ? _buildLockedView(context, isDark, textColor, subtextColor)
          : (_inPracticeMode
              ? _buildPracticeView(cardColor, textColor, subtextColor, isDark, tts, theme)
              : _buildKanjiStudyView(cardColor, textColor, subtextColor, isDark, tts, theme)),
      ),
    );
  }

  Widget _buildLockedView(BuildContext context, bool isDark, Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 56, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 20),
            Text(
              'Premium Kanji Lesson',
              style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This lesson is part of the 60% locked curriculum. Upgrade to Premium to unlock interactive Kanji stroke drawing, stroke animation, and all N5–N1 lessons without ads.',
              style: GoogleFonts.fredoka(fontSize: 14, color: subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => PremiumSubscriptionDialog.show(context),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: Text(
                'Unlock All Content',
                style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: GoogleFonts.fredoka(color: subtextColor, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= KANJI STUDY & DRAWING VIEW =================
  Widget _buildKanjiStudyView(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    TtsService tts,
    ThemeService theme,
  ) {
    if (widget.topic.kanji.isEmpty) {
      return const Center(child: Text('No Kanji in this topic.'));
    }

    final item = widget.topic.kanji[_selectedKanjiIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final canvasSize = (screenWidth - 72).clamp(180.0, 240.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Topic Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.topic.jlpt,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.topic.kanji.length} Kanji',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.topic.title,
                style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Draw, trace and master Kanji stroke order',
                style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Kanji Switcher Carousel (Horizontal List of all Kanji in lesson)
        if (widget.topic.kanji.length > 1) ...[
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.topic.kanji.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final k = widget.topic.kanji[index];
                final isSelected = index == _selectedKanjiIndex;
                final primaryReading = k.kunyomi.isNotEmpty
                    ? k.kunyomi.first
                    : (k.onyomi.isNotEmpty ? k.onyomi.first : '');

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedKanjiIndex = index;
                      _loadCurrentKanji();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          k.character.isNotEmpty ? k.character : 'Kanji ${index + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                        if (primaryReading.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            primaryReading,
                            style: GoogleFonts.fredoka(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white.withValues(alpha: 0.85) : subtextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Interactive Kanji Canvas Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Canvas mode switch (Draw vs Stroke Animation)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeTab('✍️ Draw & Trace', 0, isDark),
                  const SizedBox(width: 8),
                  _buildModeTab('🎬 Stroke Animation', 1, isDark),
                ],
              ),
              const SizedBox(height: 16),

              // The Japanese Practice Grid with Canvas
              Center(
                child: SizedBox(
                  width: canvasSize,
                  height: canvasSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Traditional Japanese square grid (田 + diagonals)
                      CustomPaint(
                        size: Size(canvasSize, canvasSize),
                        painter: _JapaneseKanjiGridPainter(isDark: isDark),
                      ),

                      if (_isLoadingKvg)
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(color: Color(0xFF8B5CF6), strokeWidth: 3),
                        )
                      else if (_canvasMode == 0) ...[
                        // Faint ghost character in background
                        Text(
                          item.character,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: item.character.length > 2
                                ? canvasSize * 0.35
                                : (item.character.length == 2 ? canvasSize * 0.46 : canvasSize * 0.72),
                            fontWeight: FontWeight.normal,
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        // User freehand drawing layer
                        GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _currentStroke = [details.localPosition];
                              _userStrokes.add(_currentStroke!);
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              _currentStroke?.add(details.localPosition);
                            });
                          },
                          onPanEnd: (_) => _currentStroke = null,
                          child: CustomPaint(
                            size: Size(canvasSize, canvasSize),
                            painter: _FreehandDrawingPainter(
                              strokes: _userStrokes,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Mode 1: Animated Stroke Order
                        if (_currentKvgData != null)
                          KanjiCanvas(
                            controller: _kanjiController,
                            size: canvasSize - 24,
                            thickness: 7.0,
                            color: const Color(0xFF8B5CF6),
                            hintColor: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08),
                          )
                        else
                          Text(
                            item.character,
                            style: TextStyle(
                              fontSize: canvasSize * 0.7,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Controls row
              if (_canvasMode == 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.strokeCount} Strokes',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (_userStrokes.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.undo_rounded, size: 20),
                            tooltip: 'Undo Stroke',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (_userStrokes.isNotEmpty) _userStrokes.removeLast();
                              });
                            },
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _userStrokes.clear());
                          },
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentKvgData?.strokes ?? item.strokeCount} Strokes',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          tooltip: 'Previous Stroke',
                          onPressed: _currentKvgData != null ? _stepPreviousStroke : null,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(10),
                            elevation: 0,
                          ),
                          onPressed: _currentKvgData != null ? () => _kanjiController.toggle() : null,
                          child: const Icon(Icons.play_arrow_rounded, size: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          tooltip: 'Next Stroke',
                          onPressed: _currentKvgData != null ? _stepNextStroke : null,
                        ),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        setState(() {
                          _speedMultiplier = _speedMultiplier == 1 ? 2 : 1;
                        });
                      },
                      child: Text('${_speedMultiplier}x', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              if (widget.topic.kanji.length > 1) ...[
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: _selectedKanjiIndex > 0 ? const Color(0xFF8B5CF6) : Colors.grey,
                      ),
                      onPressed: _selectedKanjiIndex > 0
                          ? () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedKanjiIndex--;
                                _loadCurrentKanji();
                              });
                            }
                          : null,
                    ),
                    Text(
                      '${_selectedKanjiIndex + 1} of ${widget.topic.kanji.length}',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subtextColor,
                      ),
                    ),
                    TextButton.icon(
                      label: const Text('Next'),
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      style: TextButton.styleFrom(
                        foregroundColor: _selectedKanjiIndex + 1 < widget.topic.kanji.length ? const Color(0xFF8B5CF6) : Colors.grey,
                      ),
                      onPressed: _selectedKanjiIndex + 1 < widget.topic.kanji.length
                          ? () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedKanjiIndex++;
                                _loadCurrentKanji();
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Character Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Character Details',
                    style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF8B5CF6)),
                    onPressed: () {
                      final sound = item.kunyomi.isNotEmpty ? item.kunyomi.first : item.character;
                      tts.speakJapanese(sound);
                    },
                    tooltip: 'Listen pronunciation',
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Onyomi & Kunyomi
              Row(
                children: [
                  if (item.onyomi.isNotEmpty)
                    Expanded(
                      child: _buildReadingTile('音読み (On)', item.onyomi.join(', '), const Color(0xFF8B5CF6), isDark),
                    ),
                  if (item.onyomi.isNotEmpty && item.kunyomi.isNotEmpty)
                    const SizedBox(width: 10),
                  if (item.kunyomi.isNotEmpty)
                    Expanded(
                      child: _buildReadingTile('訓読み (Kun)', item.kunyomi.join(', '), const Color(0xFF10B981), isDark),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Meanings
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: item.meanings.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    m,
                    style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6)),
                  ),
                )).toList(),
              ),

              if (item.explanation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.explanation,
                  style: GoogleFonts.fredoka(fontSize: 13, color: textColor, height: 1.35),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Common Compounds List
        if (item.commonWords.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Common Kanji Compounds:',
                  style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 10),
                ...item.commonWords.map((cw) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cw.word,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '【${cw.reading}】',
                                    style: GoogleFonts.fredoka(fontSize: 13, color: const Color(0xFF8B5CF6)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cw.meaning,
                                style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 20, color: Color(0xFF8B5CF6)),
                          onPressed: () => tts.speakJapanese(cw.word),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Practice Button
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.quiz_rounded, size: 20),
            label: Text(
              'Practice ${item.character} (${item.questions.length} Questions)',
              style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _startPracticeForKanji(_selectedKanjiIndex),
          ),
        ),

        // Full Lesson Practice Test Banner
        if (_totalQuestionsInTopic > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Full Lesson Practice Test',
                            style: GoogleFonts.fredoka(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Practice all $_totalQuestionsInTopic questions across all ${widget.topic.kanji.length} kanji in this lesson.',
                            style: GoogleFonts.fredoka(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C3AED),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _checkAndStartFullPractice,
                    child: Text(
                      'Start Full Practice Test ($_totalQuestionsInTopic Qs) →',
                      style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildModeTab(String label, int mode, bool isDark) {
    final isSelected = _canvasMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => _canvasMode = mode);
        try {
          final analytics = Provider.of<AnalyticsService>(context, listen: false);
          final char = widget.topic.kanji.isNotEmpty && _selectedKanjiIndex < widget.topic.kanji.length
              ? widget.topic.kanji[_selectedKanjiIndex].character
              : '';
          analytics.logKanjiCanvasUsed(
            character: char,
            mode: mode == 0 ? 'draw' : 'animation',
          );
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6)
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildReadingTile(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= PRACTICE VIEW =================
  Widget _buildPracticeView(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    TtsService tts,
    ThemeService theme,
  ) {
    if (_currentQuestionIndex >= _currentQuestions.length) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 54),
              ),
              const SizedBox(height: 18),
              Text(
                'Kanji Practice Completed! 🎌',
                style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $_correctCount / ${_currentQuestions.length}',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6)),
              ),
              const SizedBox(height: 8),
              Text(
                _isFullPracticeTest
                    ? 'Amazing! You finished all ${_currentQuestions.length} questions across all kanji in this lesson!'
                    : 'Excellent progress on ${widget.topic.kanji.isNotEmpty ? widget.topic.kanji[_selectedKanjiIndex].character : ""}!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
              ),
              const SizedBox(height: 24),

              if (!_isFullPracticeTest && _totalQuestionsInTopic > _currentQuestions.length) ...[
                SizedBox(
                  width: 260,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 20),
                    label: Text(
                      'Take Full Lesson Test ($_totalQuestionsInTopic Qs)',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _checkAndStartFullPractice,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: 260,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    _isFullPracticeTest ? 'Retake Full Practice' : 'Retake Kanji Practice',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    if (_isFullPracticeTest) {
                      _startFullPracticeTest();
                    } else {
                      _startPracticeForKanji(_selectedKanjiIndex);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: 260,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                  onPressed: () => setState(() => _inPracticeMode = false),
                  child: Text('Back to Kanji Drawing', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = _currentQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _currentQuestions.length;

    KanjiItem? currentKanji;
    for (final k in widget.topic.kanji) {
      if (k.questions.any((q) => q.id.toString() == question.id.toString())) {
        currentKanji = k;
        break;
      }
    }
    if (currentKanji == null && widget.topic.kanji.isNotEmpty) {
      currentKanji = widget.topic.kanji[_selectedKanjiIndex];
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_currentQuestions.length}',
              style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: subtextColor),
            ),
            Text(
              '$_correctCount Correct',
              style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),

        // Compact Native Ad above question
        const AppNativeAdWidget(compact: true, margin: EdgeInsets.only(bottom: 14)),

        // Question Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          question.type,
                          style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6)),
                        ),
                      ),
                      if (currentKanji != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${currentKanji.character} (${currentKanji.meanings.take(2).join(', ')})',
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flag_outlined, color: Color(0xFFEF4444), size: 20),
                        tooltip: 'Report question mistake',
                        onPressed: () {
                          QuestionReportDialog.show(
                            context: context,
                            questionId: question.id,
                            topicId: widget.topic.id,
                            category: 'kanji',
                            level: widget.topic.jlpt,
                            questionText: question.japanese.isNotEmpty
                                ? (question.completedSentence.isNotEmpty ? question.completedSentence : question.japanese)
                                : question.question,
                            options: question.options,
                            correctOption: question.correctOption,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF8B5CF6), size: 20),
                        tooltip: 'Copy question sentence',
                        onPressed: () {
                          final text = question.japanese.isNotEmpty
                              ? (_isAnswerSubmitted && question.completedSentence.isNotEmpty ? question.completedSentence : question.japanese)
                              : question.question;
                          ClipboardHelper.copy(context, text, label: 'Question sentence copied');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Centered TTS Speaker Button
              if (question.japanese.isNotEmpty) ...[
                Center(
                  child: Material(
                    color: isDark ? Colors.white10 : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        final text = _isAnswerSubmitted && question.completedSentence.isNotEmpty
                            ? question.completedSentence
                            : question.japanese.replaceAll('___', '');
                        tts.speakJapanese(text);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.volume_up_rounded, color: Color(0xFF8B5CF6), size: 26),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (question.japanese.isNotEmpty) ...[
                GrammarJapaneseSentenceWidget(
                  text: question.japanese,
                  showFurigana: theme.showFurigana,
                  isVibrant: theme.isVibrantText,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: textColor, height: 1.5),
                ),
                const SizedBox(height: 8),
              ],

              if (question.question.isNotEmpty)
                Text(
                  question.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Multiple Choice Options
        ...question.options.entries.map((entry) {
          final optKey = entry.key;
          final optLabel = entry.value;

          Color btnColor = cardColor;
          Color borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
          Color labelColor = textColor;

          if (_isAnswerSubmitted) {
            if (optKey == question.correctOption) {
              btnColor = const Color(0xFF10B981).withValues(alpha: 0.15);
              borderColor = const Color(0xFF10B981);
              labelColor = const Color(0xFF10B981);
            } else if (optKey == _selectedOption) {
              btnColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
              borderColor = const Color(0xFFEF4444);
              labelColor = const Color(0xFFEF4444);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isAnswerSubmitted ? null : () => _submitAnswer(optKey),
              onLongPress: () {
                ClipboardHelper.copy(context, optLabel, label: 'Option "$optLabel" copied');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isAnswerSubmitted && optKey == question.correctOption
                            ? const Color(0xFF10B981)
                            : (_isAnswerSubmitted && optKey == _selectedOption
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF8B5CF6).withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        optKey,
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isAnswerSubmitted &&
                                  (optKey == question.correctOption || optKey == _selectedOption)
                              ? Colors.white
                              : const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        optLabel,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: labelColor),
                      ),
                    ),
                    if (_isAnswerSubmitted && optKey == question.correctOption)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22)
                    else if (_isAnswerSubmitted && optKey == _selectedOption && optKey != question.correctOption)
                      const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22)
                    else
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey.shade400),
                        tooltip: 'Copy option',
                        onPressed: () {
                          ClipboardHelper.copy(context, optLabel, label: 'Option "$optLabel" copied');
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Explanation Box
        if (_isAnswerSubmitted) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedOption == question.correctOption
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedOption == question.correctOption
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _selectedOption == question.correctOption ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: _selectedOption == question.correctOption ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedOption == question.correctOption ? 'Correct! 正解' : 'Incorrect Choice',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _selectedOption == question.correctOption ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                if (question.completedSentence.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GrammarJapaneseSentenceWidget(
                    text: question.completedSentence,
                    showFurigana: theme.showFurigana,
                    isVibrant: theme.isVibrantText,
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
                if (question.english.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    question.english,
                    style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 10),

                if (_selectedOption != null &&
                    _selectedOption != question.correctOption &&
                    question.explanation.wrong.containsKey(_selectedOption)) ...[
                  Text(
                    'Why $_selectedOption is incorrect:',
                    style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    question.explanation.wrong[_selectedOption]!,
                    style: GoogleFonts.fredoka(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                  ),
                  const SizedBox(height: 10),
                ],

                Text(
                  'Explanation:',
                  style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                ),
                const SizedBox(height: 2),
                Text(
                  question.explanation.correct,
                  style: GoogleFonts.fredoka(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentQuestionIndex + 1 < _currentQuestions.length ? 'Next Question →' : 'See Results →',
                style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Traditional Japanese Kanji practice box grid lines (田 shape + diagonals)
class _JapaneseKanjiGridPainter extends CustomPainter {
  final bool isDark;

  const _JapaneseKanjiGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Crosslines (+)
    _drawDashedLine(canvas, Offset(0, center.dy), Offset(size.width, center.dy), dashPaint);
    _drawDashedLine(canvas, Offset(center.dx, 0), Offset(center.dx, size.height), dashPaint);

    // Diagonal lines (X)
    _drawDashedLine(canvas, Offset.zero, Offset(size.width, size.height), dashPaint);
    _drawDashedLine(canvas, Offset(0, size.height), Offset(size.width, 0), dashPaint);

    // Outer Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(20)),
      paint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5;
    const double dashSpace = 5;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = (p2 - p1).distance;
    final double count = distance / (dashWidth + dashSpace);
    final double xStep = dx / count;
    final double yStep = dy / count;

    for (int i = 0; i < count; i++) {
      final startX = p1.dx + (xStep * i);
      final startY = p1.dy + (yStep * i);
      final endX = startX + (xStep * (dashWidth / (dashWidth + dashSpace)));
      final endY = startY + (yStep * (dashWidth / (dashWidth + dashSpace)));
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _JapaneseKanjiGridPainter oldDelegate) => oldDelegate.isDark != isDark;
}

/// Freehand Drawing painter for practicing tracing
class _FreehandDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;

  const _FreehandDrawingPainter({required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 3.0, paint);
      } else {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FreehandDrawingPainter oldDelegate) => true;
}
