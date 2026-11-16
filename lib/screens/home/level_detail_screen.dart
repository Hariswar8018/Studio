import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grammar_model.dart';
import '../../services/ad_service.dart';
import '../../services/database_service.dart';
import '../../services/iap_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/app_native_ad_widget.dart';
import '../../widgets/premium_subscription_dialog.dart';
import '../learn/grammar_learn_screen.dart';
import '../test/random_test_screen.dart';
import '../test/srs_review_screen.dart';

class LevelDetailScreen extends StatefulWidget {
  final String level;
  final Map<String, dynamic>? levelData;

  const LevelDetailScreen({
    super.key,
    required this.level,
    this.levelData,
  });

  @override
  State<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _learnFilter = 'unlearned'; // 'unlearned', 'completed', 'all'

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
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final accentColor = widget.levelData?['accent'] as Color? ?? const Color(0xFF6366F1);
    final levelTitle = widget.levelData?['title'] as String? ?? '${widget.level} Grammar';

    final topics = db.getTopicsForLevel(widget.level);
    final dueQuestions = db.getDueSrsQuestions(level: widget.level);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const AppNativeAdWidget(
        compact: true,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.level,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                levelTitle,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor,
          unselectedLabelColor: subtextColor,
          indicatorColor: accentColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              text: 'Learning Section (${topics.length})',
            ),
            Tab(
              icon: const Icon(Icons.quiz_rounded, size: 20),
              text: 'Test Section (${dueQuestions.length} Due)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: LEARNING SECTION
          _buildLearningSection(topics, db, isDark, cardColor, textColor, subtextColor, accentColor),

          // TAB 2: TEST SECTION (SRS & Practice)
          _buildTestSection(topics, dueQuestions, isDark, cardColor, textColor, subtextColor, accentColor),
        ],
      ),
    );
  }

  Widget _buildLearningSection(
    List<GrammarTopicModel> topics,
    DatabaseService db,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color accentColor,
  ) {
    if (topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_books_rounded, size: 64, color: subtextColor),
              const SizedBox(height: 12),
              Text(
                'No Grammar Topics in ${widget.level} Yet',
                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin can upload JSON grammar topics via the Admin Studio.',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontSize: 13, color: subtextColor),
              ),
            ],
          ),
        ),
      );
    }

    final unlearnedCount = topics.where((t) => !db.isTopicCompleted(t.id)).length;
    final completedCount = topics.where((t) => db.isTopicCompleted(t.id)).length;

    final filteredTopics = topics.where((t) {
      final isCompleted = db.isTopicCompleted(t.id);
      if (_learnFilter == 'unlearned') return !isCompleted;
      if (_learnFilter == 'completed') return isCompleted;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Filter row: Unlearned | Completed | All
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Unlearned ($unlearnedCount)',
                isSelected: _learnFilter == 'unlearned',
                onTap: () => setState(() => _learnFilter = 'unlearned'),
                activeColor: accentColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Completed ($completedCount)',
                isSelected: _learnFilter == 'completed',
                onTap: () => setState(() => _learnFilter = 'completed'),
                activeColor: const Color(0xFF10B981),
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'All (${topics.length})',
                isSelected: _learnFilter == 'all',
                onTap: () => setState(() => _learnFilter = 'all'),
                activeColor: accentColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filteredTopics.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _learnFilter == 'unlearned'
                        ? Icons.check_circle_outline_rounded
                        : (_learnFilter == 'completed'
                            ? Icons.school_outlined
                            : Icons.inbox_rounded),
                    size: 48,
                    color: subtextColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _learnFilter == 'unlearned'
                        ? 'All patterns completed in ${widget.level}! 🎉'
                        : (_learnFilter == 'completed'
                            ? 'No completed patterns yet'
                            : 'No patterns found'),
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _learnFilter == 'unlearned'
                        ? 'Check "Completed" or "All" tab to review or take full tests.'
                        : 'Start learning unlearned patterns to mark them completed.',
                    style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
          ),

        ...filteredTopics.map((topic) {
          final isPrem = Provider.of<IapService>(context).isPremium;
          final isLocked = db.isGrammarTopicLocked(topic.id, isPrem);
          final isCompleted = db.isTopicCompleted(topic.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (isLocked) {
                  PremiumSubscriptionDialog.show(context);
                  return;
                }
                Provider.of<AdService>(context, listen: false).showInterstitialAdIfNeeded(isPremium: isPrem);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GrammarLearnScreen(topic: topic),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLocked
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                        : (isCompleted
                            ? const Color(0xFF10B981).withValues(alpha: 0.35)
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
                    if (isLocked) ...[
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 14),
                      ),
                      const SizedBox(width: 12),
                    ] else if (isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 12),
                    ],
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
                    ] else if (isCompleted) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF8B5CF6)),
                        label: Text(
                          'Full Test',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        onPressed: () {
                          Provider.of<AdService>(context, listen: false).showInterstitialAdIfNeeded(isPremium: isPrem);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SrsReviewScreen(topic: topic),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: subtextColor.withValues(alpha: 0.5),
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildTestSection(
    List<GrammarTopicModel> topics,
    List<GrammarQuestion> dueQuestions,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color accentColor,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // SRS Explanation Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
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
                  const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Spaced Repetition System (SRS)',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Review intervals: 1 → 2 → 4 → 8 → 12 days.\nEvery question tests nuance discrimination. In-depth explanations clarify what went wrong on mistakes.',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${dueQuestions.length} Questions Due in ${widget.level}',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Action 0: Random Test Generator (Pure Japanese Immersion, Big Pool)
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RandomTestScreen(
                  level: widget.level,
                  questionCount: null, // As big test as possible!
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Random ${widget.level} Exam Generator',
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pure JP',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No English. Generates big pool, exit & save anytime.',
                        style: GoogleFonts.fredoka(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action 1: Review Due SRS Questions
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SrsReviewScreen(
                  level: widget.level,
                  onlyDue: true,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Due Questions (${dueQuestions.length})',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled for today according to SRS intervals.',
                        style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action 2: Comprehensive Level Test
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SrsReviewScreen(
                  level: widget.level,
                  onlyDue: false,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.flash_on_rounded, color: accentColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comprehensive ${widget.level} Quiz',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Test all questions across all ${widget.level} topics.',
                        style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Topic-by-topic tests header
        Text(
          'Topic-Specific Tests',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        ...topics.map((topic) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              tileColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              title: Text(
                topic.title,
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
              ),
              subtitle: Text(
                '${topic.questions.length} questions available',
                style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SrsReviewScreen(
                        topic: topic,
                      ),
                    ),
                  );
                },
                child: Text('Test', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
      ],
    );
  }
}

