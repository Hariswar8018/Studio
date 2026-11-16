import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/vocab_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../services/tts_service.dart';
import '../../services/ad_service.dart';
import '../../services/iap_service.dart';
import '../../widgets/grammar_japanese_sentence_widget.dart';
import '../../widgets/app_native_ad_widget.dart';
import '../../widgets/premium_subscription_dialog.dart';

class VocabLearnScreen extends StatefulWidget {
  final VocabularyTopicModel topic;

  const VocabLearnScreen({super.key, required this.topic});

  @override
  State<VocabLearnScreen> createState() => _VocabLearnScreenState();
}

class _VocabLearnScreenState extends State<VocabLearnScreen> {
  bool _inPracticeMode = false;
  int _selectedWordIndex = 0;
  late List<VocabularyQuestion> _currentQuestions;
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _isAnswerSubmitted = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestionsForSelectedWord();
  }

  void _loadQuestionsForSelectedWord() {
    if (widget.topic.vocabulary.isNotEmpty) {
      final word = widget.topic.vocabulary[_selectedWordIndex];
      _currentQuestions = List.from(word.questions);
    } else {
      _currentQuestions = [];
    }
  }

  void _startPracticeForWord(int wordIndex) {
    setState(() {
      _selectedWordIndex = wordIndex;
      _loadQuestionsForSelectedWord();
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

    // Speak full sentence audio on correct or wrong
    try {
      final tts = Provider.of<TtsService>(context, listen: false);
      String audioText = question.completedSentence.isNotEmpty
          ? question.completedSentence
          : (question.japanese.isNotEmpty
              ? question.japanese
              : widget.topic.vocabulary[_selectedWordIndex].word);
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
      // Completed practice
      setState(() {
        _currentQuestionIndex++; // Points to completed
      });

      // Mark vocab topic as completed
      final db = Provider.of<DatabaseService>(context, listen: false);
      db.markVocabCompleted(widget.topic.id);

      // Trigger interstitial ad between lessons
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

    final isLocked = db.isVocabTopicLocked(widget.topic.id, iap.isPremium);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () {
            if (_inPracticeMode) {
              setState(() => _inPracticeMode = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _inPracticeMode ? 'Vocab Practice' : widget.topic.title,
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
          if (!_inPracticeMode && widget.topic.vocabulary.isNotEmpty)
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
                onPressed: () => _startPracticeForWord(0),
              ),
            ),
        ],
      ),
      body: isLocked
          ? _buildLockedView(context, isDark, textColor, subtextColor)
          : (_inPracticeMode
              ? _buildPracticeView(cardColor, textColor, subtextColor, isDark, tts, theme)
              : _buildWordListView(cardColor, textColor, subtextColor, isDark, tts, theme)),
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
              'Premium Vocabulary Lesson',
              style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This lesson is part of the 60% locked curriculum. Upgrade to Premium to unlock all Vocabulary, Kanji & Grammar lessons with zero ads.',
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

  // ================= VOCABULARY STUDY GUIDE VIEW =================
  Widget _buildWordListView(
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    TtsService tts,
    ThemeService theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Topic Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
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
                      '${widget.topic.vocabulary.length} Words',
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
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.topic.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Vocabulary Cards
        ...widget.topic.vocabulary.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Word & Reading Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.reading,
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                color: const Color(0xFF06B6D4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.word,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF06B6D4), size: 26),
                        onPressed: () => tts.speakJapanese(item.word),
                        tooltip: 'Listen pronunciation',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Meaning
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.meaning,
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                      ),
                    ),
                  ),
                  if (item.partOfSpeech.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Part of speech: ${item.partOfSpeech}',
                      style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (item.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.explanation,
                      style: GoogleFonts.fredoka(fontSize: 13, color: textColor, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Collocations
                  if (item.commonCollocations.isNotEmpty) ...[
                    Text(
                      'Common Collocations:',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...item.commonCollocations.map((col) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                col,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF06B6D4)),
                              onPressed: () => tts.speakJapanese(col),
                              tooltip: 'Listen',
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],

                  // Practice Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.quiz_rounded, size: 18),
                      label: Text(
                        'Practice ${item.word} (${item.questions.length} Qs)',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () => _startPracticeForWord(index),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
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
                'Practice Completed! 🎉',
                style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $_correctCount / ${_currentQuestions.length}',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF06B6D4)),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job practicing ${widget.topic.vocabulary[_selectedWordIndex].word}!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 240,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => setState(() => _inPracticeMode = false),
                  child: Text('Back to Word Guide', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = _currentQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _currentQuestions.length;

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
          valueColor: const AlwaysStoppedAnimation(Color(0xFF06B6D4)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      question.type,
                      style: GoogleFonts.fredoka(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF06B6D4),
                      ),
                    ),
                  ),
                  if (question.japanese.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF06B6D4)),
                      tooltip: 'Speak sentence',
                      onPressed: () {
                        final text = _isAnswerSubmitted && question.completedSentence.isNotEmpty
                            ? question.completedSentence
                            : question.japanese.replaceAll('___', '');
                        tts.speakJapanese(text);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (question.japanese.isNotEmpty) ...[
                GrammarJapaneseSentenceWidget(
                  text: question.japanese,
                  showFurigana: theme.showFurigana,
                  isVibrant: theme.isVibrantText,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (question.question.isNotEmpty)
                Text(
                  question.question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
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
                                : const Color(0xFF06B6D4).withValues(alpha: 0.1)),
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
                              : const Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        optLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        ),
                      ),
                    ),
                    if (_isAnswerSubmitted && optKey == question.correctOption)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                    if (_isAnswerSubmitted && optKey == _selectedOption && optKey != question.correctOption)
                      const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22),
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
                backgroundColor: const Color(0xFF06B6D4),
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

