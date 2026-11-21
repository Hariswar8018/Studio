import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/srs_progress_model.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';
import '../../services/theme_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/grammar_japanese_sentence_widget.dart';
import 'random_test_screen.dart';

class DifficultGrammarScreen extends StatefulWidget {
  final String category; // 'grammar', 'vocab', 'kanji'
  final String? level;

  const DifficultGrammarScreen({
    super.key,
    this.category = 'grammar',
    this.level,
  });

  @override
  State<DifficultGrammarScreen> createState() => _DifficultGrammarScreenState();
}

class _DifficultGrammarScreenState extends State<DifficultGrammarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logEvent('weak_points_viewed', parameters: {
          'category': widget.category,
          'level': widget.level ?? '',
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName() {
    if (widget.category == 'vocab') return 'Vocab';
    if (widget.category == 'kanji') return 'Kanji';
    return 'Grammar';
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final theme = Provider.of<ThemeService>(context);
    final tts = Provider.of<TtsService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final difficultQuestions = db.getDifficultUnifiedQuestions(
      level: widget.level,
      category: widget.category,
    );
    final easyQuestions = db.getEasyUnifiedQuestions(
      level: widget.level,
      category: widget.category,
    );

    final catName = _getCategoryDisplayName();

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
          '$catName Bank: Difficult vs Mastered',
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
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: subtextColor,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              text: 'Difficult (${difficultQuestions.length})',
            ),
            Tab(
              icon: const Icon(Icons.verified_rounded, size: 18),
              text: 'Mastered (${easyQuestions.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Difficult Questions
          _buildDifficultList(difficultQuestions, db, tts, isDark, cardColor, textColor, subtextColor, theme),

          // Tab 2: Easy / Mastered Questions (10+ correct tests)
          _buildEasyList(easyQuestions, db, tts, isDark, cardColor, textColor, subtextColor, theme),
        ],
      ),
      bottomNavigationBar: difficultQuestions.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.flash_on_rounded),
                  label: Text(
                    'Practice ${difficultQuestions.length} Difficult Questions',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () {
                    try {
                      final analytics = Provider.of<AnalyticsService>(context, listen: false);
                      analytics.logEvent('practice_weak_points_clicked', parameters: {
                        'category': widget.category,
                        'level': widget.level ?? '',
                      });
                    } catch (_) {}
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RandomTestScreen(
                          category: widget.category,
                          level: widget.level,
                          difficultOnly: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDifficultList(
    List<UnifiedReviewQuestion> list,
    DatabaseService db,
    TtsService tts,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    ThemeService theme,
  ) {
    final catName = _getCategoryDisplayName();
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_very_satisfied_rounded, size: 64, color: Color(0xFF10B981)),
              const SizedBox(height: 14),
              Text(
                'No Difficult $catName Yet!',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Whenever you answer a $catName question incorrectly during tests, it automatically moves to this Weak Points Bank for Spaced Repetition until you reach 10+ correct answers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final q = list[i];
        final prog = db.getQuestionProgress(q.id);
        final correctCount = prog?.correctCount ?? 0;
        final wrongCount = prog?.wrongCount ?? 0;
        final displaySentence = q.completedSentence.isNotEmpty ? q.completedSentence : q.japanese;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Needs Work ($correctCount/10 Correct)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1), size: 20),
                      onPressed: () => tts.speakJapanese(displaySentence),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GrammarJapaneseSentenceWidget(
                  text: displaySentence,
                  showFurigana: theme.showFurigana,
                  isVibrant: theme.isVibrantText,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (q.english.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    q.english,
                    style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Wrong count: $wrongCount • Topic: ${q.topicTitle}',
                  style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (correctCount / 10).clamp(0.0, 1.0),
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEasyList(
    List<UnifiedReviewQuestion> list,
    DatabaseService db,
    TtsService tts,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    ThemeService theme,
  ) {
    final catName = _getCategoryDisplayName();
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, size: 64, color: Color(0xFF6366F1)),
              const SizedBox(height: 14),
              Text(
                'No Mastered $catName Items Yet',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Questions with 10 or more correct test answers graduate into this Mastered Bank.',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final q = list[i];
        final prog = db.getQuestionProgress(q.id);
        final correctCount = prog?.correctCount ?? 10;
        final displaySentence = q.completedSentence.isNotEmpty ? q.completedSentence : q.japanese;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Mastered ($correctCount Correct Tests)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1), size: 20),
                      onPressed: () => tts.speakJapanese(displaySentence),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GrammarJapaneseSentenceWidget(
                  text: displaySentence,
                  showFurigana: theme.showFurigana,
                  isVibrant: theme.isVibrantText,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (q.english.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    q.english,
                    style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Topic: ${q.topicTitle}',
                  style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
