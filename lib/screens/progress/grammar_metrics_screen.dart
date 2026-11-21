import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';
import '../../services/iap_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/app_native_ad_widget.dart';
import '../../widgets/premium_subscription_dialog.dart';
import '../home/level_detail_screen.dart';
import '../test/difficult_grammar_screen.dart';
import '../test/srs_review_screen.dart';

class GrammarMetricsScreen extends StatefulWidget {
  const GrammarMetricsScreen({super.key});

  @override
  State<GrammarMetricsScreen> createState() => _GrammarMetricsScreenState();
}

class _GrammarMetricsScreenState extends State<GrammarMetricsScreen> {
  // 0: All / Overview, 1: Grammar, 2: Vocabulary, 3: Kanji
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView(screenName: 'GrammarMetricsScreen');
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);
    final iap = Provider.of<IapService>(context);

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    // --- Grammar Stats ---
    final totalGrammar = db.topics.length;
    final completedGrammar = db.completedTopicIds.length;
    final totalAttempts = db.totalAttempts;
    final accuracy = db.overallAccuracyRate;
    final srsDue = db.srsDueCount;
    final difficult = db.difficultCount;
    final easy = db.easyCount;

    // --- Vocab Stats ---
    final totalVocabTopics = db.totalVocabTopicsCount;
    final totalVocabWords = db.totalVocabWordsCount;
    final completedVocab = db.completedVocabCount;

    // --- Kanji Stats ---
    final totalKanjiTopics = db.totalKanjiTopicsCount;
    final totalKanjiChars = db.totalKanjiCharactersCount;
    final completedKanji = db.completedKanjiCount;

    // --- Combined Overall Stats ---
    final totalAllLessons = db.totalAllLessonsCount;
    final totalCompletedLessons = db.totalCompletedLessonsCount;
    final overallProgress = totalAllLessons == 0 ? 0.0 : (totalCompletedLessons / totalAllLessons);

    final levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Full Metrics',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          if (iap.isPremium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'PRO',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
              tooltip: 'Go Premium (No Ads)',
              onPressed: () => PremiumSubscriptionDialog.show(context),
            ),
        ],
      ),
      bottomNavigationBar: iap.isPremium
          ? null
          : const AppNativeAdWidget(
              compact: true,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Master Overview Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser?.displayName ?? 'Learner',
                            style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'JLPT ${db.selectedLevel} Active Track • Complete Japanese Analytics',
                            style: GoogleFonts.fredoka(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.military_tech_rounded, color: Color(0xFFFDE047), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${auth.currentUser?.points ?? 0} pts',
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: overallProgress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFDE047)),
                      minHeight: 9,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalCompletedLessons of $totalAllLessons total lessons completed',
                        style: GoogleFonts.fredoka(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        '${(overallProgress * 100).toInt()}% Mastered',
                        style: GoogleFonts.fredoka(
                          color: const Color(0xFFFDE047),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3-Way Summary Metric Cards (Grammar, Vocab, Kanji)
            Row(
              children: [
                Expanded(
                  child: _buildTriStatCard(
                    title: 'Grammar',
                    count: '$completedGrammar / $totalGrammar',
                    sub: '${totalGrammar == 0 ? 0 : ((completedGrammar / totalGrammar) * 100).toInt()}% Done',
                    icon: Icons.auto_stories_rounded,
                    color: const Color(0xFF6366F1),
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTriStatCard(
                    title: 'Vocab',
                    count: '$completedVocab / $totalVocabTopics',
                    sub: '$totalVocabWords words',
                    icon: Icons.translate_rounded,
                    color: const Color(0xFF06B6D4),
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTriStatCard(
                    title: 'Kanji',
                    count: '$completedKanji / $totalKanjiTopics',
                    sub: '$totalKanjiChars kanji',
                    icon: Icons.draw_rounded,
                    color: const Color(0xFF8B5CF6),
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Section Filter Tabs: [ All, Grammar, Vocab, Kanji ]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildTabPill('All Metrics', 0, isDark),
                  _buildTabPill('Grammar', 1, isDark),
                  _buildTabPill('Vocabulary', 2, isDark),
                  _buildTabPill('Kanji', 3, isDark),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Grammar KPI Cards (Shown on Tab 0 or 1)
            if (_activeTab == 0 || _activeTab == 1) ...[
              _buildSectionHeader('Grammar Mastery & Accuracy', const Color(0xFF6366F1), textColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Grammar Accuracy',
                      value: totalAttempts == 0 ? 'N/A' : '${accuracy.toStringAsFixed(1)}%',
                      sublabel: '$totalAttempts questions answered',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'SRS Due Today',
                      value: '$srsDue',
                      sublabel: 'spaced repetition due',
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFFF59E0B),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SrsReviewScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Difficult Points',
                      value: '$difficult',
                      sublabel: 'mistake bank patterns',
                      icon: Icons.flag_rounded,
                      color: const Color(0xFFEF4444),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DifficultGrammarScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Easy Mastery',
                      value: '$easy',
                      sublabel: 'fluent high retention',
                      icon: Icons.sentiment_very_satisfied_rounded,
                      color: const Color(0xFF3B82F6),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Vocabulary KPI Cards (Shown on Tab 0 or 2)
            if (_activeTab == 0 || _activeTab == 2) ...[
              _buildSectionHeader('Vocabulary & Collocations', const Color(0xFF06B6D4), textColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Vocab Topics Mastered',
                      value: '$completedVocab / $totalVocabTopics',
                      sublabel: '${totalVocabTopics == 0 ? 0 : ((completedVocab / totalVocabTopics) * 100).toInt()}% completed',
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF06B6D4),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Words in Bank',
                      value: '$totalVocabWords',
                      sublabel: '6 practice question types each',
                      icon: Icons.record_voice_over_rounded,
                      color: const Color(0xFF10B981),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Kanji KPI Cards (Shown on Tab 0 or 3)
            if (_activeTab == 0 || _activeTab == 3) ...[
              _buildSectionHeader('Kanji & Stroke Order Drawing', const Color(0xFF8B5CF6), textColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Kanji Lessons Mastered',
                      value: '$completedKanji / $totalKanjiTopics',
                      sublabel: '${totalKanjiTopics == 0 ? 0 : ((completedKanji / totalKanjiTopics) * 100).toInt()}% completed',
                      icon: Icons.border_color_rounded,
                      color: const Color(0xFF8B5CF6),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Kanji Practiced',
                      value: '$totalKanjiChars',
                      sublabel: 'drawing grid & KanjiVG strokes',
                      icon: Icons.brush_rounded,
                      color: const Color(0xFFEC4899),
                      cardColor: cardColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // JLPT Level-by-Level Matrix
            Text(
              'JLPT Level Breakdown (Grammar • Vocab • Kanji)',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            ...levels.map((lvl) {
              final lvlGrammar = db.getTopicsForLevel(lvl);
              final lvlGrammarCompleted = lvlGrammar.where((t) => db.isTopicCompleted(t.id)).length;

              final lvlVocab = db.getVocabTopicsForLevel(lvl);
              final lvlVocabCompleted = lvlVocab.where((t) => db.isVocabCompleted(t.id)).length;

              final lvlKanji = db.getKanjiTopicsForLevel(lvl);
              final lvlKanjiCompleted = lvlKanji.where((t) => db.isKanjiCompleted(t.id)).length;

              final totalLvl = lvlGrammar.length + lvlVocab.length + lvlKanji.length;
              final completedLvl = lvlGrammarCompleted + lvlVocabCompleted + lvlKanjiCompleted;
              final lvlPercent = totalLvl == 0 ? 0.0 : (completedLvl / totalLvl);

              Color lvlColor;
              switch (lvl) {
                case 'N5':
                  lvlColor = const Color(0xFF10B981);
                  break;
                case 'N4':
                  lvlColor = const Color(0xFF06B6D4);
                  break;
                case 'N3':
                  lvlColor = const Color(0xFF6366F1);
                  break;
                case 'N2':
                  lvlColor = const Color(0xFFF59E0B);
                  break;
                case 'N1':
                default:
                  lvlColor = const Color(0xFFEF4444);
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: lvlColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: lvlColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                lvl,
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: lvlColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'JLPT $lvl Mastery',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LevelDetailScreen(level: lvl)),
                          ),
                          child: Text(
                            '$completedLvl / $totalLvl (${(lvlPercent * 100).toInt()}%)',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: lvlColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: lvlPercent.clamp(0.0, 1.0),
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(lvlColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📖 Grammar: $lvlGrammarCompleted/${lvlGrammar.length}',
                          style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                        ),
                        Text(
                          '💬 Vocab: $lvlVocabCompleted/${lvlVocab.length}',
                          style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                        ),
                        Text(
                          '✍️ Kanji: $lvlKanjiCompleted/${lvlKanji.length}',
                          style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String title, int index, bool isDark) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTriStatCard({
    required String title,
    required String count,
    required String sub,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.fredoka(fontSize: 10, color: subtextColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sublabel,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subtextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.fredoka(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.fredoka(
                fontSize: 10,
                color: subtextColor.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
