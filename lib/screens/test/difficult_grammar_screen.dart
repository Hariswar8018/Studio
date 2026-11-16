import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grammar_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/grammar_japanese_sentence_widget.dart';
import 'random_test_screen.dart';

class DifficultGrammarScreen extends StatefulWidget {
  const DifficultGrammarScreen({super.key});

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    final difficultQuestions = db.getDifficultQuestions();
    final easyQuestions = db.getEasyQuestions();

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
          'Grammar Bank: Difficult vs Easy',
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
              text: 'Easy / Mastered (${easyQuestions.length})',
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RandomTestScreen(difficultOnly: true),
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
    List<GrammarQuestion> list,
    DatabaseService db,
    TtsService tts,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    ThemeService theme,
  ) {
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
                'No Difficult Grammar Yet!',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Whenever you answer a question incorrectly during tests, it automatically moves to this Difficult Grammar Bank for Spaced Repetition until you reach 10+ correct answers.',
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
        final topic = db.getTopicForQuestion(q.id);
        final correctCount = prog?.correctCount ?? 0;
        final wrongCount = prog?.wrongCount ?? 0;

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
                      onPressed: () => tts.speakJapanese(q.completedSentence),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GrammarJapaneseSentenceWidget(
                  text: q.completedSentence,
                  showFurigana: theme.showFurigana,
                  isVibrant: theme.isVibrantText,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Wrong count: $wrongCount • Topic: ${topic?.title ?? "General"}',
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
    List<GrammarQuestion> list,
    DatabaseService db,
    TtsService tts,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    ThemeService theme,
  ) {
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
                'No Easy / Mastered Items Yet',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'A sentence grammar requires 10+ correct tests to graduate into this Easy Word & Grammar Bank. Keep taking random exams!',
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
        final topic = db.getTopicForQuestion(q.id);
        final correctCount = prog?.correctCount ?? 10;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GrammarJapaneseSentenceWidget(
                        text: q.completedSentence,
                        showFurigana: theme.showFurigana,
                        isVibrant: theme.isVibrantText,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mastered ($correctCount correct tests) • ${topic?.title ?? ""}',
                        style: GoogleFonts.fredoka(fontSize: 12, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF6366F1)),
                  onPressed: () => tts.speakJapanese(q.completedSentence),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
