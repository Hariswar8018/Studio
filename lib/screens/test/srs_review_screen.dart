import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grammar_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../services/tts_service.dart';
import '../../services/ad_service.dart';
import '../../services/iap_service.dart';
import '../../widgets/grammar_japanese_sentence_widget.dart';
import '../../widgets/app_native_ad_widget.dart';

class SrsReviewScreen extends StatefulWidget {
  final String? level;
  final GrammarTopicModel? topic;
  final bool onlyDue;

  const SrsReviewScreen({
    super.key,
    this.level,
    this.topic,
    this.onlyDue = false,
  });

  @override
  State<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends State<SrsReviewScreen> {
  late List<_ReviewItem> _items = [];
  int _currentIndex = 0;
  String? _selectedOption;
  bool _isAnswerSubmitted = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    final db = Provider.of<DatabaseService>(context, listen: false);
    List<GrammarTopicModel> topicsToUse = [];

    if (widget.topic != null) {
      topicsToUse = [widget.topic!];
    } else if (widget.level != null) {
      topicsToUse = db.getTopicsForLevel(widget.level!);
    } else {
      topicsToUse = db.topics;
    }

    final List<_ReviewItem> list = [];
    for (final topic in topicsToUse) {
      for (final q in topic.questions) {
        final progress = db.getQuestionProgress(q.id);
        if (widget.onlyDue) {
          if (progress == null || progress.isDue) {
            list.add(_ReviewItem(topic: topic, question: q));
          }
        } else {
          list.add(_ReviewItem(topic: topic, question: q));
        }
      }
    }

    // Shuffle questions to prevent positional bias
    list.shuffle();

    setState(() {
      _items = list;
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
    final isCorrect = (optionKey == item.question.correctOption);

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
    db.recordQuestionAttempt(item.question.id, isCorrect);

    // Speak full sentence audio on correct or wrong
    try {
      final tts = Provider.of<TtsService>(context, listen: false);
      String audioText = item.question.completedSentence.isNotEmpty
          ? item.question.completedSentence
          : item.question.japanese;
      if (audioText.contains('___')) {
        final effectiveOpts = item.question.getEffectiveOptions(item.topic.globalOptions);
        final fill = effectiveOpts[item.question.correctOption.toString()] ?? '';
        audioText = audioText.replaceAll('___', fill);
      }
      tts.speak(audioText);
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
      final adService = Provider.of<AdService>(context, listen: false);
      final iap = Provider.of<IapService>(context, listen: false);
      adService.showRewardedAdAfterTest(isPremium: iap.isPremium);
    }
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

    final title = widget.topic != null
        ? widget.topic!.title
        : (widget.level != null ? '${widget.level} SRS Review' : 'Global SRS Review');

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 64, color: Color(0xFF10B981)),
            const SizedBox(height: 14),
            Text(
              'No Questions Due for Review!',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'You have reviewed all scheduled items. You can still practice all questions anytime by starting a non-due quiz.',
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
                setState(() {
                  _loadQuestions();
                });
              },
              child: Text('Review All Questions', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
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
    final question = item.question;
    final topic = item.topic;
    final progress = db.getQuestionProgress(question.id);
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
                  topic.jlpt,
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
                  '${topic.title} • ${topic.category}',
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
                  Text(
                    'Select the most natural grammar expression:',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: subtextColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1)),
                    tooltip: 'Listen to sentence',
                    onPressed: () {
                      final textToSpeak = _isAnswerSubmitted
                          ? question.completedSentence
                          : question.japanese.replaceAll('___', '');
                      tts.speakJapanese(textToSpeak);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GrammarJapaneseSentenceWidget(
                text: question.japanese,
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
        ...question.getEffectiveOptions(topic.globalOptions).entries.map((entry) {
          final optionKey = entry.key;
          final optionLabel = entry.value;
          final globalOpt = topic.globalOptions[optionKey];

          Color btnColor = cardColor;
          Color borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
          Color labelColor = textColor;

          if (_isAnswerSubmitted) {
            if (optionKey == question.correctOption) {
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
                        color: _isAnswerSubmitted && optionKey == question.correctOption
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
                                  (optionKey == question.correctOption || optionKey == _selectedOption)
                              ? Colors.white
                              : const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            optionLabel,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: labelColor,
                            ),
                          ),
                          if (_isAnswerSubmitted && globalOpt != null && globalOpt.meaning.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              globalOpt.meaning,
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_isAnswerSubmitted && optionKey == question.correctOption)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                    if (_isAnswerSubmitted &&
                        optionKey == _selectedOption &&
                        optionKey != question.correctOption)
                      const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
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
                // Completed Sentence
                Row(
                  children: [
                    Icon(
                      _selectedOption == question.correctOption
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: _selectedOption == question.correctOption
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedOption == question.correctOption
                          ? 'Correct! Promoted in SRS.'
                          : 'Incorrect - Nuance Clarification:',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _selectedOption == question.correctOption
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GrammarJapaneseSentenceWidget(
                  text: question.completedSentence,
                  showFurigana: theme.showFurigana,
                  isVibrant: theme.isVibrantText,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.english,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: subtextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),

                // Clarify what went wrong with chosen option
                if (_selectedOption != null &&
                    _selectedOption != question.correctOption &&
                    question.explanation.wrong.containsKey(_selectedOption)) ...[
                  Text(
                    '❌ Why Option $_selectedOption (${question.getEffectiveOptions(topic.globalOptions)[_selectedOption] ?? ''}) is incorrect:',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    question.explanation.wrong[_selectedOption]!,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Explain why correct option fits
                Text(
                  '✅ Why Option ${question.correctOption} (${question.getEffectiveOptions(topic.globalOptions)[question.correctOption] ?? ''}) fits perfectly:',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  question.explanation.correct,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
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

        // Bottom overflow container showing words in review
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

class _ReviewItem {
  final GrammarTopicModel topic;
  final GrammarQuestion question;

  _ReviewItem({required this.topic, required this.question});
}
