import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedStatus = 'all'; // 'all', 'pending', 'resolved'
  String _selectedCategory = 'all'; // 'all', 'grammar', 'vocab', 'kanji'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final db = Provider.of<DatabaseService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final allReports = db.reports;
    final filtered = allReports.where((r) {
      if (_selectedStatus != 'all' && r.status != _selectedStatus) return false;
      if (_selectedCategory != 'all' && r.category.toLowerCase() != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesText = r.questionText.toLowerCase().contains(q);
        final matchesReason = r.reportedReason.toLowerCase().contains(q);
        final matchesComment = r.userComment.toLowerCase().contains(q);
        final matchesId = r.questionId.toLowerCase().contains(q);
        if (!matchesText && !matchesReason && !matchesComment && !matchesId) return false;
      }
      return true;
    }).toList();

    final pendingCount = allReports.where((r) => r.status == 'pending').length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Reported Questions',
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: pendingCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$pendingCount Pending',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter & Search bar header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.fredoka(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search by question, reason, or notes...',
                    hintStyle: GoogleFonts.fredoka(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6366F1)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),

                // Status & Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status filters
                      _buildFilterChip('All Status', 'all', _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Pending', 'pending', _selectedStatus, (v) => setState(() => _selectedStatus = v), badgeColor: const Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Resolved', 'resolved', _selectedStatus, (v) => setState(() => _selectedStatus = v), badgeColor: const Color(0xFF10B981)),
                      const SizedBox(width: 14),
                      Container(width: 1, height: 20, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(width: 14),

                      // Category filters
                      _buildFilterChip('All Types', 'all', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Grammar', 'grammar', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Vocab', 'vocab', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                      const SizedBox(width: 6),
                      _buildFilterChip('Kanji', 'kanji', _selectedCategory, (v) => setState(() => _selectedCategory = v)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.done_all_rounded, size: 56, color: isDark ? Colors.white24 : Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No reported questions found',
                          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: subtextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All submitted feedback is resolved or filters are empty.',
                          style: GoogleFonts.fredoka(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final report = filtered[index];
                      return _buildReportCard(context, report, db, cardColor, textColor, subtextColor, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected, {
    Color? badgeColor,
  }) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      labelStyle: GoogleFonts.fredoka(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : (badgeColor ?? const Color(0xFF64748B)),
      ),
      selected: isSelected,
      selectedColor: badgeColor ?? const Color(0xFF6366F1),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? Colors.transparent : (badgeColor?.withValues(alpha: 0.5) ?? Colors.grey.shade300),
      ),
      onSelected: (_) => onSelected(value),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    QuestionReportModel report,
    DatabaseService db,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final isPending = report.status == 'pending';
    final dateStr = DateFormat('MMM d, h:mm a').format(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Badges + status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${report.level} • ${report.category.toUpperCase()}',
                  style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.reportedReason,
                  style: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPending ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Question Text
          Text(
            report.questionText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 8),

          // Options preview
          if (report.options.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.options.entries.map((opt) {
                  final isCorrect = opt.key == report.correctOption;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isCorrect ? const Color(0xFF10B981) : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            opt.key,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                              color: isCorrect ? const Color(0xFF10B981) : textColor,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // User Comment / proposed fix
          if (report.userComment.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_rounded, size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'User note: "${report.userComment}"',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.amber.shade200 : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Footer: Timestamp & Admin Actions
          Row(
            children: [
              Text(
                dateStr,
                style: GoogleFonts.fredoka(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
              ),
              const Spacer(),

              // Delete Report Button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                tooltip: 'Delete report',
                onPressed: () => _confirmDeleteReport(context, report, db),
              ),

              // Toggle Status Button
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  isPending ? Icons.check_circle_outline_rounded : Icons.replay_rounded,
                  size: 16,
                  color: isPending ? const Color(0xFF10B981) : Colors.grey,
                ),
                label: Text(
                  isPending ? 'Mark Done' : 'Reopen',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPending ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
                onPressed: () async {
                  final newStatus = isPending ? 'resolved' : 'pending';
                  await db.updateReportStatus(report.id, newStatus);
                },
              ),
              const SizedBox(width: 4),

              // EDIT QUESTION & OPTIONS BUTTON
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(
                  'Edit Question',
                  style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showEditQuestionDialog(context, report, db, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReport(BuildContext context, QuestionReportModel report, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Report?', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this report record?', style: GoogleFonts.fredoka(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.fredoka())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await db.deleteReport(report.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Delete', style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditQuestionDialog(
    BuildContext context,
    QuestionReportModel report,
    DatabaseService db,
    bool isDark,
  ) {
    final questionController = TextEditingController(text: report.questionText);
    String selectedCorrect = report.correctOption.isNotEmpty ? report.correctOption : 'A';

    final optionControllers = <String, TextEditingController>{};
    report.options.forEach((k, v) {
      optionControllers[k] = TextEditingController(text: v);
    });

    if (optionControllers.isEmpty) {
      optionControllers['A'] = TextEditingController();
      optionControllers['B'] = TextEditingController();
      optionControllers['C'] = TextEditingController();
      optionControllers['D'] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit Question & Options',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category: ${report.category.toUpperCase()} • Level: ${report.level} • ID: ${report.questionId}',
                        style: GoogleFonts.fredoka(fontSize: 12, color: const Color(0xFF6366F1), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Question / Japanese Sentence
                      Text('Question Sentence (use ___ for blanks):', style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: questionController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Options & Correct Selector
                      Text('Options & Correct Choice:', style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...optionControllers.entries.map((entry) {
                        final isCorrect = entry.key == selectedCorrect;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => setDialogState(() => selectedCorrect = entry.key),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isCorrect ? const Color(0xFF10B981) : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: entry.value,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Option ${entry.key}',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text(
                        '* Tap the option letter badge (A/B/C/D) to set the correct answer (green).',
                        style: GoogleFonts.fredoka(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
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
                    final updatedOptions = <String, String>{};
                    optionControllers.forEach((k, v) {
                      updatedOptions[k] = v.text.trim();
                    });

                    final newQText = questionController.text.trim();
                    final success = await db.updateQuestionContent(
                      category: report.category,
                      questionId: report.questionId,
                      newJapanese: newQText,
                      newCompletedSentence: newQText.replaceAll('___', updatedOptions[selectedCorrect] ?? ''),
                      newOptions: updatedOptions,
                      newCorrectOption: selectedCorrect,
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Question updated & report marked as resolved!'
                                : 'Question updated locally. Please review.',
                          ),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  child: Text('Save & Resolve', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
