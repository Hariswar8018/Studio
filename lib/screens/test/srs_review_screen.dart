import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grammar_model.dart';
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

class SrsReviewScreen extends StatefulWidget {
  final String? level;
  final GrammarTopicModel? topic;
  final bool onlyDue;
  final String category; // 'grammar', 'vocab', 'kanji'

  const SrsReviewScreen({
    super.key,
    this.level,
    this.topic,
    this.onlyDue = false,
    this.category = 'grammar',
  });

  @override
  State<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends State<SrsReviewScreen> {
  late List<UnifiedReviewQuestion> _items = [];
  int _currentIndex = 0;
  String? _selectedOption;
  bool _isAnswerSubmitted = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions(onlyDue: widget.onlyDue);
  }

  void _loadQuestions({bool onlyDue = true}) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    List<UnifiedReviewQuestion> list = [];

    if (widget.topic != null) {
      list = db.getUnifiedQuestions(topicId: widget.topic!.id, category: 'grammar');
      if (onlyDue) {
        list = list.where((q) {
          final p = db.getQuestionProgress(q.id);
          return p == null || p.isDue;
        }).toList();
      }
    } else if (onlyDue) {
      list = db.getDueUnifiedQuestions(level: widget.level, category: widget.category);
    } else {
      list = db.getUnifiedQuestions(level: widget.level, category: widget.category);
    }

    // Shuffle questions to prevent positional bias
    list.shuffle();

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      analytics.logSrsReviewStarted(
        category: widget.category,
        dueCount: list.length,
        level: widget.level,
      );
    } catch (_) {}

    setState(() {
      _items = list;
      _currentIndex = 0;
      _selectedOption = null;
      _isAnswerSubmitted = false;
      _correctCount = 0;
      _wrongCount = 0;
      _loading = false;
    });
  }

  String _formatCountBadge(int count) {
    if (count >= 50) return '50+';
    if (count >= 20) return '20+';
    if (count >= 10) return '10+';
    return '$count';
  }

  void _submitAnswer(String optionKey) {
    if (_isAnswerSubmitted || _items.isEmpty) return;

    final item = _items[_currentIndex];
    final isCorrect = (optionKey == item.correctOption);

    setState(() {
      _selectedOption = optionKey;
      _isAnswerSubmitted = true;
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

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
    if (_currentIndex + 1 < _items.length) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswerSubmitted = false;
      });
    } else {
      setState(() {
        _currentIndex++; // triggers summary
      });

      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logSrsReviewCompleted(
          category: widget.category,
          correctCount: _correctCount,
          totalCount: _items.length,
        );
      } catch (_) {}

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
    final db = Provider.of<DatabaseService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final catName = _getCategoryDisplayName();
    final title = widget.topic != null
        ? widget.topic!.title
        : (widget.level != null ? '${widget.level} $catName SRS Review' : 'Global $catName SRS Review');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 18,
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
          // Top Right Badge with review count
          Container(
            margin: const EdgeInsets.only(right: 14, top: 11, bottom: 11),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _formatCountBadge(_items.length),
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty
              ? _buildEmptyView(textColor, subtextColor)
              : (_currentIndex >= _items.length
                  ? _buildSummaryView(cardColor, textColor, subtextColor, isDark)
                  : _buildQuizView(cardColor, textColor, subtextColor, isDark, tts, db, theme))),
    );
  }

  Widget _buildEmptyView(Color textColor, Color subtextColor) {
    final catName = _getCategoryDisplayName();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 64, color: Color(0xFF10B981)),
            const SizedBox(height: 14),
            Text(
              'No $catName Due for Review!',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'You have reviewed all scheduled $catName items. You can still practice all questions anytime by starting a non-due review session.',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _loadQuestions(onlyDue: false);
              },
              child: Text('Review All $catName Questions', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    TtsService tts,
    DatabaseService db,
    ThemeService theme,
  ) {
    final item = _items[_currentIndex];
    final progress = db.getQuestionProgress(item.id);
    final stage = progress?.stage ?? 0;
    final interval = progress?.intervalDays ?? 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SRS Stage and Progress Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SRS Stage $stage ($interval d)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.jlpt,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
            Text(
              '${_currentIndex + 1} / ${_items.length}',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: subtextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _items.length,
          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),

        // Compact Native Ad above question
        const AppNativeAdWidget(compact: true, margin: EdgeInsets.only(bottom: 14)),

        // Topic title banner
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

        // Japanese Question Card
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
                      item.questionText.isNotEmpty
                          ? item.questionText
                          : 'Select the most natural option:',
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

        // Detailed Explanation Box (Clarifies what went wrong)
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
                // Completed Sentence
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
                          ? 'Correct! Promoted in SRS.'
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

                // Clarify what went wrong with chosen option
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

                // Explain why correct option fits
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

          // Next Question Button
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
                _currentIndex + 1 < _items.length ? 'Next Question →' : 'Finish Session →',
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              'Session Complete! 🎉',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% Accuracy ($percentage% Retention)',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Correct', '$_correctCount', const Color(0xFF10B981)),
                  _buildStatItem('Needs Review', '$_wrongCount', const Color(0xFFEF4444)),
                  _buildStatItem('Total', '$total', textColor),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Correct answers moved forward in the SRS interval schedule:\n1 → 2 → 4 → 8 → 12 days.',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 13,
                color: subtextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
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
                child: Text('Done', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
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
          style: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
