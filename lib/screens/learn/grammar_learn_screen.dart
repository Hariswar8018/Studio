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
import '../../widgets/premium_subscription_dialog.dart';
import '../test/srs_review_screen.dart';

class GrammarLearnScreen extends StatefulWidget {
  final GrammarTopicModel topic;

  const GrammarLearnScreen({super.key, required this.topic});

  @override
  State<GrammarLearnScreen> createState() => _GrammarLearnScreenState();
}

class _GrammarLearnScreenState extends State<GrammarLearnScreen> {
  // Practice session state
  bool _inPracticeMode = false;
  late List<GrammarQuestion> _practiceQuestions;
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _isAnswerSubmitted = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    // Take first 5 questions for quick practice
    _practiceQuestions = widget.topic.questions.take(5).toList();
  }

  void _submitAnswer(String optionKey) {
    if (_isAnswerSubmitted) return;

    final question = _practiceQuestions[_currentQuestionIndex];
    final isCorrect = (optionKey == question.correctOption);

    setState(() {
      _selectedOption = optionKey;
      _isAnswerSubmitted = true;
      if (isCorrect) _correctCount++;
    });

    // Save SRS progress
    final db = Provider.of<DatabaseService>(context, listen: false);
    db.recordQuestionAttempt(question.id, isCorrect);

    // Speak full sentence audio on correct or wrong
    try {
      final tts = Provider.of<TtsService>(context, listen: false);
      String audioText = question.completedSentence.isNotEmpty
          ? question.completedSentence
          : question.japanese;
      if (audioText.contains('___')) {
        final effectiveOpts = question.getEffectiveOptions(widget.topic.globalOptions);
        final fill = effectiveOpts[question.correctOption.toString()] ?? '';
        audioText = audioText.replaceAll('___', fill);
      }
      tts.speak(audioText);
    } catch (e) {
      debugPrint('TTS playback error: $e');
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex + 1 < _practiceQuestions.length) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _isAnswerSubmitted = false;
      });
    } else {
      // Completed practice
      setState(() {
        _currentQuestionIndex++; // Points to completed
      });
      // Mark lesson as completed
      final db = Provider.of<DatabaseService>(context, listen: false);
      db.markTopicCompleted(widget.topic.id);

      // Trigger interstitial ad between lessons/tests
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
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final isLocked = db.isGrammarTopicLocked(widget.topic.id, iap.isPremium);

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
          _inPracticeMode ? 'Quick Practice (5 Qs)' : widget.topic.title,
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
          if (!_inPracticeMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text('Practice', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => setState(() => _inPracticeMode = true),
              ),
            ),
        ],
      ),
      body: isLocked
          ? _buildLockedView(context, isDark, textColor, subtextColor)
          : (_inPracticeMode
              ? _buildPracticeView(cardColor, textColor, subtextColor, isDark, tts, theme)
              : _buildUsageGuideView(cardColor, textColor, subtextColor, isDark, tts)),
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
              'Premium Grammar Lesson',
              style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This lesson is part of the 60% locked curriculum. Upgrade to Premium to unlock all Grammar, Vocabulary & Kanji lessons with zero ads.',
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

  // ================= USAGE GUIDE VIEW =================
  Widget _buildUsageGuideView(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    TtsService tts,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Topic Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                      widget.topic.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.topic.title,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.topic.description,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Title: Grammar Point Comparison
        Row(
          children: [
            const Icon(Icons.compare_arrows_rounded, color: Color(0xFF6366F1), size: 22),
            const SizedBox(width: 8),
            Text(
              'Grammar Discrimination & Usages',
              style: GoogleFonts.fredoka(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Global Options Detail Cards (A, B, C...)
        ...widget.topic.globalOptions.entries.map((entry) {
          final key = entry.key;
          final option = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Option badge & Japanese Grammar Title
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          key,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.grammar,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1)),
                        onPressed: () => tts.speakJapanese(option.grammar),
                        tooltip: 'Listen pronunciation',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Meaning
                  _buildDetailRow(
                    'Meaning',
                    option.meaning,
                    textColor,
                    subtextColor,
                    isDark,
                    Icons.translate_rounded,
                  ),
                  const SizedBox(height: 8),

                  // Structure / Formula
                  _buildDetailRow(
                    'Structure',
                    option.structure,
                    textColor,
                    subtextColor,
                    isDark,
                    Icons.account_tree_rounded,
                  ),
                  const SizedBox(height: 8),

                  // Usage
                  _buildDetailRow(
                    'Usage & Nuance',
                    option.usage,
                    textColor,
                    subtextColor,
                    isDark,
                    Icons.lightbulb_outline_rounded,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),

        // Instructions Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.topic.instructions,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF78350F),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Start Practice Button
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.quiz_rounded, size: 22),
            label: Text(
              'Start 5-Question Quick Practice',
              style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () => setState(() => _inPracticeMode = true),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color subtextColor,
    bool isDark,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.fredoka(
                fontSize: 12,
                color: subtextColor,
                height: 1.3,
              ),
            ),
          ),
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
    // If finished all 5 questions
    if (_currentQuestionIndex >= _practiceQuestions.length) {
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
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 54,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Lesson Completed! ✅',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $_correctCount / ${_practiceQuestions.length}',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pattern marked as Completed. Ready to challenge all ${widget.topic.questions.length} questions?',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
              ),
              const SizedBox(height: 24),

              // Option to do Full Length Test for this topic
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
                  icon: const Icon(Icons.bolt_rounded, size: 22),
                  label: Text(
                    'Full Length Test (${widget.topic.questions.length} Qs)',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SrsReviewScreen(topic: widget.topic),
                      ),
                    );
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
                    side: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                  onPressed: () {
                    setState(() {
                      _inPracticeMode = false;
                      _currentQuestionIndex = 0;
                      _correctCount = 0;
                      _selectedOption = null;
                      _isAnswerSubmitted = false;
                    });
                  },
                  child: Text('Review Usage Guide', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Level Topics', style: GoogleFonts.fredoka(color: textColor)),
              ),
            ],
          ),
        ),
      );
    }

    final question = _practiceQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _practiceQuestions.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress Bar & Count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_practiceQuestions.length}',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: subtextColor,
              ),
            ),
            Text(
              '$_correctCount Correct',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),

        // Compact Native Ad above question card
        const AppNativeAdWidget(compact: true, margin: EdgeInsets.only(bottom: 14)),

        // Japanese Sentence Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
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
                    'Fill in the blank:',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: subtextColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1)),
                    tooltip: 'Speak sentence',
                    onPressed: () {
                      final textToSpeak = _isAnswerSubmitted
                          ? question.completedSentence
                          : question.japanese.replaceAll('___', '');
                      tts.speakJapanese(textToSpeak);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
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

        // Multiple Choice Options (A, B, C...)
        ...question.getEffectiveOptions(widget.topic.globalOptions).entries.map((entry) {
          final optionKey = entry.key;
          final optionLabel = entry.value;
          final globalOpt = widget.topic.globalOptions[optionKey];

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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isAnswerSubmitted && optionKey == question.correctOption
                            ? const Color(0xFF10B981)
                            : (_isAnswerSubmitted && optionKey == _selectedOption
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF6366F1).withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        optionKey,
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
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
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                    if (_isAnswerSubmitted &&
                        optionKey == _selectedOption &&
                        optionKey != question.correctOption)
                      const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22),
                  ],
                ),
              ),
            ),
          );
        }),

        // Detailed Explanation Box (Appears after submission)
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
                          : Icons.info_outline_rounded,
                      color: _selectedOption == question.correctOption
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedOption == question.correctOption
                          ? 'Correct! 正解'
                          : 'Incorrect Choice - Here\'s What Went Wrong:',
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
                    fontWeight: FontWeight.w700,
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

                // If user answered wrongly, explain why the chosen wrong option fails
                if (_selectedOption != null &&
                    _selectedOption != question.correctOption &&
                    question.explanation.wrong.containsKey(_selectedOption)) ...[
                  Text(
                    'Why $_selectedOption (${question.getEffectiveOptions(widget.topic.globalOptions)[_selectedOption] ?? ''}) is wrong:',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    question.explanation.wrong[_selectedOption]!,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Explain why correct is correct
                Text(
                  'Why ${question.correctOption} is correct:',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  question.explanation.correct,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    height: 1.3,
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
                _currentQuestionIndex + 1 < _practiceQuestions.length
                    ? 'Next Question →'
                    : 'See Results →',
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

