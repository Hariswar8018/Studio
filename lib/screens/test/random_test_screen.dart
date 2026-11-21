import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/srs_progress_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../services/tts_service.dart';
import '../../services/ad_service.dart';
import '../../services/analytics_service.dart';
import '../../services/iap_service.dart';
import '../../widgets/grammar_japanese_sentence_widget.dart';
import '../../widgets/app_native_ad_widget.dart';
import '../../widgets/clipboard_helper.dart';
import '../../widgets/question_report_dialog.dart';

class RandomTestScreen extends StatefulWidget {
  final String? level;
  final bool difficultOnly;
  final int? questionCount;
  final String category; // 'grammar', 'vocab', 'kanji'

  const RandomTestScreen({
    super.key,
    this.level,
    this.difficultOnly = false,
    this.questionCount,
    this.category = 'grammar',
  });

  @override
  State<RandomTestScreen> createState() => _RandomTestScreenState();
}

class _RandomTestScreenState extends State<RandomTestScreen> {
  late List<UnifiedReviewQuestion> _testItems = [];
  int _currentIndex = 0;
  String? _selectedOption;
  bool _isAnswerSubmitted = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isLoading = true;
  bool _isFinished = false;

  final List<UnifiedReviewQuestion> _difficultAdded = [];
  final List<UnifiedReviewQuestion> _easyGraduated = [];

  @override
  void initState() {
    super.initState();
    _generateTest();
  }

  void _generateTest() {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final items = db.generateUnifiedRandomTest(
      level: widget.level,
      category: widget.category,
      count: widget.questionCount ?? 15,
      difficultOnly: widget.difficultOnly,
    );

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      analytics.logEvent('random_test_started', parameters: {
        'level': widget.level ?? '',
        'category': widget.category,
        'difficultOnly': widget.difficultOnly ? 1 : 0,
        'questionCount': items.length,
      });
    } catch (_) {}

    setState(() {
      _testItems = items;
      _isLoading = false;
    });
  }

  void _submitAnswer(String optionKey) {
    if (_isAnswerSubmitted || _testItems.isEmpty) return;

    final item = _testItems[_currentIndex];
    final isCorrect = (optionKey == item.correctOption);

    setState(() {
      _selectedOption = optionKey;
      _isAnswerSubmitted = true;
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
        _difficultAdded.add(item);
      }
    });

    // Record in DatabaseService and Spaced Repetition
    final db = Provider.of<DatabaseService>(context, listen: false);
    db.recordQuestionAttempt(item.id, isCorrect, category: item.category);

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      analytics.logQuestionAnswered(
        lessonId: item.topicId,
        category: item.category,
        questionIndex: _currentIndex,
        questionId: item.id,
        isCorrect: isCorrect,
        selectedOption: optionKey,
        correctOption: item.correctOption,
      );
    } catch (_) {}

    // Check if item has now reached 10+ correct tests
    final progress = db.getQuestionProgress(item.id);
    if (progress != null && progress.correctCount >= 10) {
      _easyGraduated.add(item);
    }

    // Speak full sentence audio on correct or wrong
    try {
      final tts = Provider.of<TtsService>(context, listen: false);
      String audioText = item.completedSentence.isNotEmpty
          ? item.completedSentence
          : item.japanese;
      if (audioText.contains('___')) {
        final fill = item.options[item.correctOption] ?? '';
        audioText = audioText.replaceAll('___', fill);
      }
      tts.speakJapanese(audioText);
    } catch (e) {
      debugPrint('TTS playback error: $e');
    }
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < _testItems.length) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswerSubmitted = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });

      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logEvent('random_test_completed', parameters: {
          'level': widget.level ?? '',
          'category': widget.category,
          'difficultOnly': widget.difficultOnly ? 1 : 0,
          'totalQuestions': _testItems.length,
          'correctCount': _correctCount,
          'wrongCount': _wrongCount,
        });
      } catch (_) {}

      final adService = Provider.of<AdService>(context, listen: false);
      final iap = Provider.of<IapService>(context, listen: false);
      adService.showRewardedAdAfterTest(isPremium: iap.isPremium);
    }
  }

  Future<void> _confirmExitEarly() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answeredCount = _correctCount + _wrongCount;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app_rounded, color: Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 8),
            Text(
              'Exit & Save Progress?',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'You have answered $answeredCount of ${_testItems.length} questions.\n\nAll results will be saved. Mistakes are added to Spaced Repetition.',
          style: GoogleFonts.fredoka(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Testing', style: GoogleFonts.fredoka()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Save & Exit', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      if (!mounted) return;
      setState(() {
        _isFinished = true;
      });
      final adService = Provider.of<AdService>(context, listen: false);
      final iap = Provider.of<IapService>(context, listen: false);
      adService.showRewardedAdAfterTest(isPremium: iap.isPremium);
    }
  }

  String _getCategoryDisplayName() {
    if (widget.category == 'vocab') return 'Vocab';
    if (widget.category == 'kanji') return 'Kanji';
    return 'Grammar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final tts = Provider.of<TtsService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final catName = _getCategoryDisplayName();
    final title = widget.difficultOnly
        ? (widget.level != null ? '${widget.level} $catName Weak Points' : '$catName Weak Points Exam')
        : (widget.level != null ? '${widget.level} $catName Quick Test' : '$catName Practice Exam');

    return PopScope(
      canPop: _isFinished || _currentIndex == 0 && !_isAnswerSubmitted,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmExitEarly();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: textColor),
            tooltip: 'Exit & Save Progress',
            onPressed: _isFinished ? () => Navigator.pop(context) : _confirmExitEarly,
          ),
          title: Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            // Real-time Furigana / Romaji Toggle
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
            // Real-time Colorful Words Toggle
            IconButton(
              tooltip: theme.isVibrantText ? 'Colorful Words: ON' : 'Colorful Words: OFF',
              icon: Icon(
                Icons.palette_rounded,
                color: theme.isVibrantText ? const Color(0xFFEC4899) : subtextColor,
                size: 20,
              ),
              onPressed: () => theme.toggleVibrantText(),
            ),
            // Top Right Counter
            Container(
              margin: const EdgeInsets.only(right: 14, top: 11, bottom: 11),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_testItems.length} Qs',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (_testItems.isEmpty
                ? _buildEmptyState(textColor, subtextColor)
                : (_isFinished
                    ? _buildSummaryView(cardColor, textColor, subtextColor, isDark)
                    : _buildExamView(cardColor, textColor, subtextColor, isDark, tts, theme))),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subtextColor) {
    final catName = _getCategoryDisplayName();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 64, color: Color(0xFF6366F1)),
            const SizedBox(height: 14),
            Text(
              'No $catName Questions Found',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'No practice questions are available for the selected level and filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back', style: GoogleFonts.fredoka(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamView(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    TtsService tts,
    ThemeService theme,
  ) {
    final item = _testItems[_currentIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Question ${_currentIndex + 1} of ${_testItems.length}',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 4),
                Text('$_correctCount', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF10B981))),
                const SizedBox(width: 10),
                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 4),
                Text('$_wrongCount', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFEF4444))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _testItems.length,
          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),

        // Compact Native Ad
        const AppNativeAdWidget(compact: true, margin: EdgeInsets.only(bottom: 14)),

        // Topic banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.bookmark_outline_rounded, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.topicTitle} • ${item.badgeText}',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Japanese Sentence Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
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
                  Expanded(
                    child: Text(
                      item.questionText.isNotEmpty ? item.questionText : 'Select the natural answer:',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subtextColor,
                      ),
                    ),
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
                            questionId: item.id,
                            topicId: item.topicId,
                            category: item.category,
                            level: item.jlpt,
                            questionText: item.completedSentence.isNotEmpty ? item.completedSentence : item.japanese,
                            options: item.options,
                            correctOption: item.correctOption,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF6366F1), size: 20),
                        tooltip: 'Copy question sentence',
                        onPressed: () {
                          final textToCopy = item.completedSentence.isNotEmpty ? item.completedSentence : item.japanese;
                          ClipboardHelper.copy(context, textToCopy, label: 'Question sentence copied');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Centered TTS Speaker Button
              Center(
                child: Material(
                  color: isDark ? Colors.white10 : const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final textToSpeak = _isAnswerSubmitted
                          ? (item.completedSentence.isNotEmpty ? item.completedSentence : item.japanese)
                          : item.japanese.replaceAll('___', '');
                      tts.speakJapanese(textToSpeak);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1), size: 26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              GrammarJapaneseSentenceWidget(
                text: item.japanese,
                showFurigana: theme.showFurigana,
                isVibrant: theme.isVibrantText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Multiple Choice Options
        ...item.options.entries.map((entry) {
          final optionKey = entry.key;
          final optionLabel = entry.value;

          Color btnColor = cardColor;
          Color borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
          Color labelColor = textColor;

          if (_isAnswerSubmitted) {
            if (optionKey == item.correctOption) {
              btnColor = const Color(0xFF10B981).withValues(alpha: 0.15);
              borderColor = const Color(0xFF10B981);
              labelColor = const Color(0xFF10B981);
            } else if (optionKey == _selectedOption) {
              btnColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
              borderColor = const Color(0xFFEF4444);
              labelColor = const Color(0xFFEF4444);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isAnswerSubmitted ? null : () => _submitAnswer(optionKey),
              onLongPress: () {
                ClipboardHelper.copy(context, optionLabel, label: 'Option "$optionLabel" copied');
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _isAnswerSubmitted && optionKey == item.correctOption
                            ? const Color(0xFF10B981)
                            : (_isAnswerSubmitted && optionKey == _selectedOption
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6366F1).withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        optionKey,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isAnswerSubmitted &&
                                  (optionKey == item.correctOption || optionKey == _selectedOption)
                              ? Colors.white
                              : const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        optionLabel,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        ),
                      ),
                    ),
                    if (_isAnswerSubmitted && optionKey == item.correctOption)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24)
                    else if (_isAnswerSubmitted &&
                        optionKey == _selectedOption &&
                        optionKey != item.correctOption)
                      const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24)
                    else
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey.shade400),
                        tooltip: 'Copy option',
                        onPressed: () {
                          ClipboardHelper.copy(context, optionLabel, label: 'Option "$optionLabel" copied');
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Detailed Explanation Box
        if (_isAnswerSubmitted) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedOption == item.correctOption
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedOption == item.correctOption
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
                      _selectedOption == item.correctOption
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: _selectedOption == item.correctOption
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedOption == item.correctOption
                          ? 'Correct!'
                          : 'Incorrect - Review Explanation:',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _selectedOption == item.correctOption
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                if (item.completedSentence.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GrammarJapaneseSentenceWidget(
                    text: item.completedSentence,
                    showFurigana: theme.showFurigana,
                    isVibrant: theme.isVibrantText,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
                if (item.english.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.english,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: subtextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                if (_selectedOption != null &&
                    _selectedOption != item.correctOption &&
                    item.wrongExplanations.containsKey(_selectedOption)) ...[
                  Text(
                    '❌ Why Option $_selectedOption (${item.options[_selectedOption] ?? ''}) is incorrect:',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.wrongExplanations[_selectedOption]!,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (item.explanation.isNotEmpty) ...[
                  Text(
                    '✅ Why Option ${item.correctOption} (${item.options[item.correctOption] ?? ''}) fits:',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.explanation,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex + 1 < _testItems.length ? 'Next Question →' : 'Finish Test →',
                style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildSummaryView(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final total = _correctCount + _wrongCount;
    final percentage = total > 0 ? ((_correctCount / total) * 100).round() : 0;
    final catName = _getCategoryDisplayName();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              'Exam Session Saved! 📊',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Answered $total questions with $percentage% accuracy',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 18),

            // Statistics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Correct', '$_correctCount', const Color(0xFF10B981)),
                  _buildStatItem('Difficult (Wrong)', '$_wrongCount', const Color(0xFFEF4444)),
                  _buildStatItem('Total Answered', '$total', textColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Difficult Bank Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_alt_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$catName Weak Points Bank (+${_difficultAdded.length} saved)',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFFEF4444), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'All incorrect $catName questions were scheduled in your Spaced Repetition queue for 1-day review. Questions require 10+ correct tests to graduate into Easy Words.',
                    style: GoogleFonts.fredoka(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155), height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Done & Return', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.fredoka(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
