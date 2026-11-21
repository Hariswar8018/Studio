import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/grammar_model.dart';
import '../../models/vocab_model.dart';
import '../../models/kanji_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../learn/grammar_learn_screen.dart';
import '../vocab/vocab_learn_screen.dart';
import '../kanji/kanji_learn_screen.dart';
import 'admin_upload_screen.dart';
import 'admin_reports_screen.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  String _selectedLevel = 'ALL'; // 'ALL', 'N5', 'N4', 'N3', 'N2', 'N1'
  String _selectedCategory = 'ALL'; // 'ALL', 'grammar', 'vocab', 'kanji'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _levels = ['ALL', 'N5', 'N4', 'N3', 'N2', 'N1'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditTitleDialog(
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
              'Change the displayed title for this lesson.',
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


  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    // Calculate Stats by Level
    final levelFilter = _selectedLevel == 'ALL' ? null : _selectedLevel;

    final filteredGrammar = db.topics.where((t) {
      final matchesLevel = levelFilter == null || t.jlpt.toUpperCase() == levelFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery) ||
          t.description.toLowerCase().contains(_searchQuery);
      return matchesLevel && matchesSearch;
    }).toList();

    final filteredVocab = db.vocabTopics.where((t) {
      final matchesLevel = levelFilter == null || t.jlpt.toUpperCase() == levelFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery) ||
          t.vocabulary.any((v) => v.word.toLowerCase().contains(_searchQuery) || v.meaning.toLowerCase().contains(_searchQuery));
      return matchesLevel && matchesSearch;
    }).toList();

    final filteredKanji = db.kanjiTopics.where((t) {
      final matchesLevel = levelFilter == null || t.jlpt.toUpperCase() == levelFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery) ||
          t.kanji.any((k) => k.character.contains(_searchQuery) || k.meanings.any((m) => m.toLowerCase().contains(_searchQuery)));
      return matchesLevel && matchesSearch;
    }).toList();

    // Stats calculations for level
    final grammarCount = levelFilter == null ? db.topics.length : db.getTopicsForLevel(levelFilter).length;
    final grammarQuestionsTotal = (levelFilter == null ? db.topics : db.getTopicsForLevel(levelFilter))
        .fold<int>(0, (sum, t) => sum + t.questions.length);

    final vocabCount = levelFilter == null ? db.vocabTopics.length : db.getVocabTopicsForLevel(levelFilter).length;
    final vocabWordsTotal = (levelFilter == null ? db.vocabTopics : db.getVocabTopicsForLevel(levelFilter))
        .fold<int>(0, (sum, t) => sum + t.vocabulary.length);

    final kanjiCount = levelFilter == null ? db.kanjiTopics.length : db.getKanjiTopicsForLevel(levelFilter).length;
    final kanjiTotal = (levelFilter == null ? db.kanjiTopics : db.getKanjiTopicsForLevel(levelFilter))
        .fold<int>(0, (sum, t) => sum + t.kanji.length);

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
          'Lessons & Curriculum Stats',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.flag_rounded, color: Color(0xFFEF4444)),
                if (db.pendingReportsCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      alignment: Alignment.center,
                      child: Text(
                        '${db.pendingReportsCount}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'View Question Reports (${db.pendingReportsCount} Pending)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
            tooltip: 'Upload / Create Lesson',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LEVEL SELECTOR PILLS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _levels.map((lvl) {
                final isSelected = _selectedLevel == lvl;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(lvl, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6366F1),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedLevel = lvl);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // TOP STATS CARDS
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Curriculum Breakdown ($_selectedLevel)',
                      style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${grammarCount + vocabCount + kanjiCount} Total Lessons',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildStatCard(
                      title: 'Grammar',
                      count: grammarCount,
                      subText: '$grammarQuestionsTotal Questions',
                      color: const Color(0xFF6366F1),
                      icon: Icons.auto_stories_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'Vocab',
                      count: vocabCount,
                      subText: '$vocabWordsTotal Words',
                      color: const Color(0xFF06B6D4),
                      icon: Icons.translate_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'Kanji',
                      count: kanjiCount,
                      subText: '$kanjiTotal Kanji',
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.draw_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SEARCH BAR & CATEGORY FILTER
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            style: GoogleFonts.fredoka(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search lessons by title, words, meaning...',
              hintStyle: GoogleFonts.fredoka(color: subtextColor, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // CATEGORY SEGMENTS
          Row(
            children: [
              _buildCategoryPill('All (${filteredGrammar.length + filteredVocab.length + filteredKanji.length})', 'ALL'),
              const SizedBox(width: 8),
              _buildCategoryPill('Grammar (${filteredGrammar.length})', 'grammar'),
              const SizedBox(width: 8),
              _buildCategoryPill('Vocab (${filteredVocab.length})', 'vocab'),
              const SizedBox(width: 8),
              _buildCategoryPill('Kanji (${filteredKanji.length})', 'kanji'),
            ],
          ),
          const SizedBox(height: 16),

          // LESSONS LIST
          if (_selectedCategory == 'ALL' || _selectedCategory == 'grammar') ...[
            if (filteredGrammar.isNotEmpty) ...[
              _buildSectionHeader('Grammar Lessons (${filteredGrammar.length})', const Color(0xFF6366F1), textColor),
              const SizedBox(height: 8),
              ...filteredGrammar.map((t) => _buildGrammarCard(context, t, db, cardColor, textColor, subtextColor, isDark)),
              const SizedBox(height: 14),
            ],
          ],

          if (_selectedCategory == 'ALL' || _selectedCategory == 'vocab') ...[
            if (filteredVocab.isNotEmpty) ...[
              _buildSectionHeader('Vocabulary Lessons (${filteredVocab.length})', const Color(0xFF06B6D4), textColor),
              const SizedBox(height: 8),
              ...filteredVocab.map((t) => _buildVocabCard(context, t, db, cardColor, textColor, subtextColor, isDark)),
              const SizedBox(height: 14),
            ],
          ],

          if (_selectedCategory == 'ALL' || _selectedCategory == 'kanji') ...[
            if (filteredKanji.isNotEmpty) ...[
              _buildSectionHeader('Kanji Lessons (${filteredKanji.length})', const Color(0xFF8B5CF6), textColor),
              const SizedBox(height: 8),
              ...filteredKanji.map((t) => _buildKanjiCard(context, t, db, cardColor, textColor, subtextColor, isDark)),
              const SizedBox(height: 14),
            ],
          ],

          if (filteredGrammar.isEmpty && filteredVocab.isEmpty && filteredKanji.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'No published lessons found',
                      style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try changing your level filter or search keywords.',
                      style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required String subText,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            Text(
              subText,
              style: GoogleFonts.fredoka(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String label, String cat) {
    final isSelected = _selectedCategory == cat;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedCategory = cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey,
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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }

  Widget _buildGrammarCard(
    BuildContext context,
    GrammarTopicModel t,
    DatabaseService db,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onDoubleTap: () => _showEditTitleDialog(context, t.id, t.title, 'grammar'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.jlpt,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.title,
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${t.questions.length} Questions • ${t.globalOptions.length} Patterns • ${t.category}',
                style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                    label: Text('View Full Page', style: GoogleFonts.fredoka(fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GrammarLearnScreen(topic: t)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 20),
                    tooltip: 'Edit Title (or Double Click)',
                    onPressed: () => _showEditTitleDialog(context, t.id, t.title, 'grammar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVocabCard(
    BuildContext context,
    VocabularyTopicModel t,
    DatabaseService db,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final preview = t.vocabulary.take(3).map((v) => v.word).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onDoubleTap: () => _showEditTitleDialog(context, t.id, t.title, 'vocab'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.jlpt,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.title,
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${t.vocabulary.length} Words ($preview) • 6 Qs each',
                style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                    label: Text('View Full Page', style: GoogleFonts.fredoka(fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VocabLearnScreen(topic: t)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 20),
                    tooltip: 'Edit Title (or Double Click)',
                    onPressed: () => _showEditTitleDialog(context, t.id, t.title, 'vocab'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKanjiCard(
    BuildContext context,
    KanjiTopicModel t,
    DatabaseService db,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final preview = t.kanji.take(4).map((k) => k.character).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onDoubleTap: () => _showEditTitleDialog(context, t.id, t.title, 'kanji'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t.jlpt,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.title,
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${t.kanji.length} Characters ($preview) • Readings & Examples',
                style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                    label: Text('View Full Page', style: GoogleFonts.fredoka(fontSize: 12)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => KanjiLearnScreen(topic: t)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 20),
                    tooltip: 'Edit Title (or Double Click)',
                    onPressed: () => _showEditTitleDialog(context, t.id, t.title, 'kanji'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

