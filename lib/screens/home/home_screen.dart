import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grammar_model.dart';
import '../../models/vocab_model.dart';
import '../../models/kanji_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';
import '../../services/iap_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/app_native_ad_widget.dart';
import '../../widgets/premium_subscription_dialog.dart';
import '../settings/settings_screen.dart';
import '../test/difficult_grammar_screen.dart';
import '../test/random_test_screen.dart';
import '../test/srs_review_screen.dart';
import '../learn/grammar_learn_screen.dart';
import '../vocab/vocab_learn_screen.dart';
import '../kanji/kanji_learn_screen.dart';
import '../admin/admin_lessons_screen.dart';
import '../admin/admin_upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0: Grammar, 1: Vocabulary, 2: Kanji
  int _selectedTab = 0;

  static const List<String> _allLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  String get _currentCategory {
    if (_selectedTab == 1) return 'vocab';
    if (_selectedTab == 2) return 'kanji';
    return 'grammar';
  }

  String get _currentCategoryName {
    if (_selectedTab == 1) return 'Vocab';
    if (_selectedTab == 2) return 'Kanji';
    return 'Grammar';
  }

  void _handleDoubleTapLesson(
    BuildContext context,
    String topicId,
    String currentTitle,
    String category,
  ) {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAdmin) return;
    _showEditLessonTitleDialog(context, topicId, currentTitle, category);
  }

  void _showEditLessonTitleDialog(
    BuildContext context,
    String topicId,
    String currentTitle,
    String category,
  ) {
    final theme = Provider.of<ThemeService>(context, listen: false);
    final isDark = theme.isDarkMode;
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 24),
            const SizedBox(width: 8),
            Text(
              'Edit Lesson Name',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Shortcut: Change the displayed title for this lesson.',
              style: GoogleFonts.fredoka(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.fredoka(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                labelText: 'Lesson Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.fredoka()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != currentTitle) {
                final db = Provider.of<DatabaseService>(context, listen: false);
                if (category == 'vocab') {
                  await db.updateVocabTopicTitle(topicId, newTitle);
                } else if (category == 'kanji') {
                  await db.updateKanjiTopicTitle(topicId, newTitle);
                } else {
                  await db.updateGrammarTopicTitle(topicId, newTitle);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Renamed to "$newTitle" successfully!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLevelSelectorSheet(BuildContext context, DatabaseService db, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Switch JLPT Level',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a level to view its Grammar, Vocabulary & Kanji lessons',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                ..._allLevels.map((lvl) {
                  final isCurrent = db.selectedLevel.toUpperCase() == lvl;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final analytics = Provider.of<AnalyticsService>(context, listen: false);
                        await db.setSelectedLevel(lvl);
                        try {
                          analytics.logLevelSelected(level: lvl);
                        } catch (_) {}
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF6366F1)
                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? const Color(0xFF6366F1)
                                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                lvl,
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _getLevelSubtitle(lvl),
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (isCurrent)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLevelSubtitle(String level) {
    switch (level) {
      case 'N5':
        return 'N5 Beginner (基礎)';
      case 'N4':
        return 'N4 Elementary (初級)';
      case 'N3':
        return 'N3 Intermediate (中級)';
      case 'N2':
        return 'N2 Pre-Advanced (上級)';
      case 'N1':
        return 'N1 Advanced Mastery (最高峰)';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final iap = Provider.of<IapService>(context);
    final theme = Provider.of<ThemeService>(context);
    final auth = Provider.of<AuthService>(context);
    final isDark = theme.isDarkMode;
    final isAdmin = auth.isAdmin;
    final canAccessLocked = iap.isPremium || isAdmin;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final currentLevel = db.selectedLevel;
    final grammarList = db.getTopicsForLevel(currentLevel);
    final vocabList = db.getVocabTopicsForLevel(currentLevel);
    final kanjiList = db.getKanjiTopicsForLevel(currentLevel);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const AppNativeAdWidget(
        compact: true,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/image.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LangNova',
                  style: GoogleFonts.fredoka(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Japanese Studio',
                  style: GoogleFonts.fredoka(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Level Selector Pill Badge
            
          ],
        ),
        actions: [
          // Theme Switcher (Dark or Light Mode)
          InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showLevelSelectorSheet(context, db, isDark),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLevel,
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => theme.toggleTheme(),
          ),

          // Admin shortcut button (ONLY if admin Gmail login)
          if (auth.isAdmin)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded, size: 15, color: Color(0xFF10B981)),
                    
                    if (db.pendingReportsCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${db.pendingReportsCount}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              tooltip: 'Admin Studio & Lessons',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLessonsScreen()),
                );
              },
            ),
          // Settings
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white70 : const Color(0xFF475569)),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 3-Way Segment Toggle: Grammar | Vocabulary | Kanji
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildSegmentButton(
                  title: 'Grammar',
                  count: grammarList.length,
                  icon: Icons.auto_stories_rounded,
                  index: 0,
                  isDark: isDark,
                  color: const Color(0xFF6366F1),
                ),
                _buildSegmentButton(
                  title: 'Vocab',
                  count: vocabList.length,
                  icon: Icons.translate_rounded,
                  index: 1,
                  isDark: isDark,
                  color: const Color(0xFF06B6D4),
                ),
                _buildSegmentButton(
                  title: 'Kanji',
                  count: kanjiList.length,
                  icon: Icons.draw_rounded,
                  index: 2,
                  isDark: isDark,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action Hub (Spaced Repetition Review, Random Test, Difficult Bank)
          _buildQuickActionHub(context, db, isDark, cardColor, textColor, subtextColor),
          const SizedBox(height: 18),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getSectionTitle(currentLevel),
                style: GoogleFonts.fredoka(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                '${_getActiveItemCount(grammarList, vocabList, kanjiList)} Lessons',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Content List
          if (_selectedTab == 0)
            _buildGrammarList(grammarList, db, cardColor, textColor, subtextColor, isDark, canAccessLocked)
          else if (_selectedTab == 1)
            _buildVocabList(vocabList, db, cardColor, textColor, subtextColor, isDark, canAccessLocked)
          else
            _buildKanjiList(kanjiList, db, cardColor, textColor, subtextColor, isDark, canAccessLocked),

          const SizedBox(height: 72),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(
                'Upload JSON',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
                );
              },
            )
          : null,
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required int count,
    required IconData icon,
    required int index,
    required bool isDark,
    required Color color,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _selectedTab = index);
          try {
            final cat = index == 0 ? 'grammar' : (index == 1 ? 'vocab' : 'kanji');
            final analytics = Provider.of<AnalyticsService>(context, listen: false);
            analytics.logCategorySelected(category: cat);
          } catch (_) {}
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ),
             
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionHub(
    BuildContext context,
    DatabaseService db,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
  ) {
    final currentCat = _currentCategory;
    final catName = _currentCategoryName;
    final srsDue = db.getCategorySrsDueCount(currentCat, level: db.selectedLevel);
    final diffDue = db.getCategoryDifficultDueCount(currentCat, level: db.selectedLevel);
    final diffCount = db.getCategoryDifficultCount(currentCat, level: db.selectedLevel);

    return Row(
      children: [
        // Spaced Repetition Due Card
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logEvent('srs_hub_clicked', parameters: {
                  'category': currentCat,
                  'level': db.selectedLevel,
                  'dueCount': srsDue,
                });
              } catch (_) {}
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SrsReviewScreen(
                    level: db.selectedLevel,
                    onlyDue: true,
                    category: currentCat,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history_edu_rounded, size: 16, color: Color(0xFF6366F1)),
                      ),
                      if (srsDue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            srsDue >= 50
                                ? '50+ Due'
                                : (srsDue >= 20
                                    ? '20+ Due'
                                    : (srsDue >= 10 ? '10+ Due' : '$srsDue Due')),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$catName SRS',
                    style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    srsDue > 0 ? '$srsDue items' : 'All okay!',
                    style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Quick Test Card
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logEvent('quick_quiz_clicked', parameters: {
                  'category': currentCat,
                  'level': db.selectedLevel,
                });
              } catch (_) {}
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RandomTestScreen(
                    level: db.selectedLevel,
                    questionCount: 15,
                    category: currentCat,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF06B6D4)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick Quiz',
                    style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Random Quiz',
                    style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Difficult / Weak Points Bank
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logEvent('weak_points_clicked', parameters: {
                  'category': currentCat,
                  'level': db.selectedLevel,
                });
              } catch (_) {}
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DifficultGrammarScreen(
                    category: currentCat,
                    level: db.selectedLevel,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
                      ),
                      if (diffDue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            diffDue >= 50
                                ? '50+ Due'
                                : (diffDue >= 20
                                    ? '20+ Due'
                                    : (diffDue >= 10 ? '10+ Due' : '$diffDue Due')),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Weak Points',
                    style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    diffCount > 0 ? '$diffCount items' : 'All mastered!',
                    style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getSectionTitle(String level) {
    switch (_selectedTab) {
      case 0:
        return '$level Grammar Topics';
      case 1:
        return '$level Vocabulary Lessons';
      case 2:
        return '$level Kanji Lessons';
      default:
        return '$level Lessons';
    }
  }

  int _getActiveItemCount(List g, List v, List k) {
    if (_selectedTab == 0) return g.length;
    if (_selectedTab == 1) return v.length;
    return k.length;
  }

  // --- GRAMMAR LIST VIEW ---
  Widget _buildGrammarList(
    List<GrammarTopicModel> list,
    DatabaseService db,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    bool canAccessLocked,
  ) {
    if (list.isEmpty) {
      return _buildEmptyState('No Grammar lessons available for ${db.selectedLevel}', isDark, subtextColor);
    }

    final freeCount = (list.length * 0.6).ceil();

    return Column(
      children: list.asMap().entries.map((entry) {
        final index = entry.key;
        final topic = entry.value;
        final isLocked = !canAccessLocked && index >= freeCount;
        final isCompleted = db.isTopicCompleted(topic.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onDoubleTap: () => _handleDoubleTapLesson(context, topic.id, topic.title, 'grammar'),
            onTap: () {
              if (isLocked) {
                try {
                  final analytics = Provider.of<AnalyticsService>(context, listen: false);
                  analytics.logPaywallViewed(source: 'locked_grammar_lesson');
                } catch (_) {}
                PremiumSubscriptionDialog.show(context);
                return;
              }
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logLessonStarted(
                  lessonId: topic.id,
                  level: topic.jlpt,
                  category: 'grammar',
                  title: topic.title,
                );
              } catch (_) {}
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GrammarLearnScreen(topic: topic)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                      : (isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : (isDark ? Colors.white12 : Colors.grey.shade200)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : (isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF6366F1).withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : (isCompleted ? Icons.check_circle_rounded : Icons.auto_stories_rounded),
                      color: isLocked
                          ? const Color(0xFFF59E0B)
                          : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic.title,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked ? textColor.withValues(alpha: 0.85) : textColor,
                                ),
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'PRO',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLocked
                              ? 'Premium Lesson • Tap to unlock 60% locked content'
                              : '${topic.questions.length} Questions • ${topic.category}',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: isLocked ? const Color(0xFFF59E0B) : subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                    size: isLocked ? 18 : 14,
                    color: isLocked ? const Color(0xFFF59E0B) : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- VOCABULARY LIST VIEW ---
  Widget _buildVocabList(
    List<VocabularyTopicModel> list,
    DatabaseService db,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    bool canAccessLocked,
  ) {
    if (list.isEmpty) {
      return _buildEmptyState('No Vocabulary lessons available for ${db.selectedLevel}', isDark, subtextColor);
    }

    final freeCount = (list.length * 0.6).ceil();

    return Column(
      children: list.asMap().entries.map((entry) {
        final index = entry.key;
        final topic = entry.value;
        final isLocked = !canAccessLocked && index >= freeCount;
        final isCompleted = db.isVocabCompleted(topic.id);
        final wordPreview = topic.vocabulary.isNotEmpty
            ? topic.vocabulary.map((v) => v.word).take(3).join(', ')
            : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onDoubleTap: () => _handleDoubleTapLesson(context, topic.id, topic.title, 'vocab'),
            onTap: () {
              if (isLocked) {
                try {
                  final analytics = Provider.of<AnalyticsService>(context, listen: false);
                  analytics.logPaywallViewed(source: 'locked_vocab_lesson');
                } catch (_) {}
                PremiumSubscriptionDialog.show(context);
                return;
              }
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logLessonStarted(
                  lessonId: topic.id,
                  level: topic.jlpt,
                  category: 'vocab',
                  title: topic.title,
                );
              } catch (_) {}
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VocabLearnScreen(topic: topic)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                      : (isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : (isDark ? Colors.white12 : Colors.grey.shade200)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : (isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF06B6D4).withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : (isCompleted ? Icons.check_circle_rounded : Icons.translate_rounded),
                      color: isLocked
                          ? const Color(0xFFF59E0B)
                          : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF06B6D4)),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic.title,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked ? textColor.withValues(alpha: 0.85) : textColor,
                                ),
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'PRO',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLocked
                              ? 'Premium Vocabulary • Tap to unlock 60% locked content'
                              : '${topic.vocabulary.length} Words ($wordPreview) • 6 Qs each',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: isLocked ? const Color(0xFFF59E0B) : subtextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                    size: isLocked ? 18 : 14,
                    color: isLocked ? const Color(0xFFF59E0B) : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- KANJI LIST VIEW ---
  Widget _buildKanjiList(
    List<KanjiTopicModel> list,
    DatabaseService db,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
    bool canAccessLocked,
  ) {
    if (list.isEmpty) {
      return _buildEmptyState('No Kanji lessons available for ${db.selectedLevel}', isDark, subtextColor);
    }

    final freeCount = (list.length * 0.6).ceil();

    return Column(
      children: list.asMap().entries.map((entry) {
        final index = entry.key;
        final topic = entry.value;
        final isLocked = !canAccessLocked && index >= freeCount;
        final isCompleted = db.isKanjiCompleted(topic.id);
        final kanjiChars = topic.kanji.map((k) => k.character).take(4).join(' ');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onDoubleTap: () => _handleDoubleTapLesson(context, topic.id, topic.title, 'kanji'),
            onTap: () {
              if (isLocked) {
                try {
                  final analytics = Provider.of<AnalyticsService>(context, listen: false);
                  analytics.logPaywallViewed(source: 'locked_kanji_lesson');
                } catch (_) {}
                PremiumSubscriptionDialog.show(context);
                return;
              }
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logLessonStarted(
                  lessonId: topic.id,
                  level: topic.jlpt,
                  category: 'kanji',
                  title: topic.title,
                );
              } catch (_) {}
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KanjiLearnScreen(topic: topic)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                      : (isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : (isDark ? Colors.white12 : Colors.grey.shade200)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : (isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF8B5CF6).withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: isLocked
                        ? const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 22)
                        : Text(
                            topic.kanji.isNotEmpty ? topic.kanji.first.character : '漢',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic.title,
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isLocked ? textColor.withValues(alpha: 0.85) : textColor,
                                ),
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'PRO',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLocked
                              ? 'Premium Kanji • Tap to unlock 60% locked content'
                              : '${topic.kanji.length} Kanji ($kanjiChars) • Stroke Drawing & 6 Qs',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: isLocked ? const Color(0xFFF59E0B) : subtextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                    size: isLocked ? 18 : 14,
                    color: isLocked ? const Color(0xFFF59E0B) : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message, bool isDark, Color subtextColor) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final totalLessons = db.totalAllLessonsCount;
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 36, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
          ),
          if (totalLessons > 0) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text('Switch Level (Available in N2/N3)', style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _showLevelSelectorSheet(context, db, isDark),
            ),
          ],
        ],
      ),
    );
  }
}
