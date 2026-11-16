import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/sample_grammar_data.dart';
import '../../models/grammar_model.dart';
import '../../models/vocab_model.dart';
import '../../models/kanji_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _jsonController = TextEditingController();

  // Detected parsed models
  GrammarTopicModel? _parsedGrammarTopic;
  VocabularyTopicModel? _parsedVocabTopic;
  KanjiTopicModel? _parsedKanjiTopic;
  String _detectedType = 'grammar'; // 'grammar' | 'vocab' | 'kanji'

  String? _parseError;
  bool _isSaving = false;
  int _manageTab = 0; // 0: Grammar, 1: Vocab, 2: Kanji

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _validateJson(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedGrammarTopic = null;
        _parsedVocabTopic = null;
        _parsedKanjiTopic = null;
        _parseError = null;
      });
      return;
    }

    try {
      final dynamic decoded = jsonDecode(text.trim());
      if (decoded is! Map<String, dynamic>) {
        setState(() {
          _parsedGrammarTopic = null;
          _parsedVocabTopic = null;
          _parsedKanjiTopic = null;
          _parseError = 'Root of JSON must be an object { ... }';
        });
        return;
      }

      final section = decoded['section']?.toString().toLowerCase() ?? '';

      if (decoded.containsKey('vocabulary') || section == 'vocabulary') {
        final vocab = VocabularyTopicModel.fromMap(decoded);
        setState(() {
          _detectedType = 'vocab';
          _parsedVocabTopic = vocab;
          _parsedGrammarTopic = null;
          _parsedKanjiTopic = null;
          _parseError = null;
        });
      } else if (decoded.containsKey('kanji') || section == 'kanji') {
        final kanji = KanjiTopicModel.fromMap(decoded);
        setState(() {
          _detectedType = 'kanji';
          _parsedKanjiTopic = kanji;
          _parsedGrammarTopic = null;
          _parsedVocabTopic = null;
          _parseError = null;
        });
      } else {
        final grammar = GrammarTopicModel.fromJson(decoded);
        setState(() {
          _detectedType = 'grammar';
          _parsedGrammarTopic = grammar;
          _parsedVocabTopic = null;
          _parsedKanjiTopic = null;
          _parseError = null;
        });
      }
    } catch (e) {
      setState(() {
        _parsedGrammarTopic = null;
        _parsedVocabTopic = null;
        _parsedKanjiTopic = null;
        _parseError = 'Invalid JSON: $e';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null && text.trim().isNotEmpty) {
        _jsonController.text = text;
        _validateJson(text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pasted JSON from clipboard! (${text.length} chars)',
                style: GoogleFonts.fredoka(),
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Clipboard is empty or contains no text.', style: GoogleFonts.fredoka()),
              backgroundColor: const Color(0xFFF59E0B),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read clipboard: $e')),
      );
    }
  }

  void _loadSampleGrammar() {
    final sample = SampleGrammarData.getSampleN2NoRelationship();
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(sample);
    _jsonController.text = formatted;
    _validateJson(formatted);
  }

  void _loadSampleVocab() {
    final sample = SampleGrammarData.getSampleN2VocabUsage();
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(sample);
    _jsonController.text = formatted;
    _validateJson(formatted);
  }

  void _loadSampleKanji() {
    final sample = SampleGrammarData.getSampleN2KanjiUsage();
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(sample);
    _jsonController.text = formatted;
    _validateJson(formatted);
  }

  Future<void> _uploadAndSave() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    setState(() => _isSaving = true);

    try {
      if (_detectedType == 'vocab' && _parsedVocabTopic != null) {
        await db.saveVocabTopic(_parsedVocabTopic!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved Vocabulary Topic "${_parsedVocabTopic!.title}"!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else if (_detectedType == 'kanji' && _parsedKanjiTopic != null) {
        await db.saveKanjiTopic(_parsedKanjiTopic!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved Kanji Topic "${_parsedKanjiTopic!.title}"!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else if (_parsedGrammarTopic != null) {
        await db.saveGrammarTopic(_parsedGrammarTopic!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved Grammar Topic "${_parsedGrammarTopic!.title}"!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }

      _jsonController.clear();
      setState(() {
        _parsedGrammarTopic = null;
        _parsedVocabTopic = null;
        _parsedKanjiTopic = null;
        _parseError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving topic: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final bool hasValidPayload =
        _parsedGrammarTopic != null || _parsedVocabTopic != null || _parsedKanjiTopic != null;

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
          'LangNova Admin JSON Studio',
          style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Admin Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: auth.isAdmin
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: auth.isAdmin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  auth.isAdmin ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
                  color: auth.isAdmin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    auth.isAdmin
                        ? 'Admin Verified: ${auth.currentUser?.email}'
                        : 'Read-only mode. Sign in as admin to publish.',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: auth.isAdmin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Template Loaders Row
          Text(
            'Load Sample Templates:',
            style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTemplateBtn('📖 Grammar Template', _loadSampleGrammar, const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                _buildTemplateBtn('💬 Vocab (6 Qs)', _loadSampleVocab, const Color(0xFF06B6D4)),
                const SizedBox(width: 8),
                _buildTemplateBtn('✍️ Kanji (6 Qs)', _loadSampleKanji, const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _buildTemplateBtn('📋 Paste Clipboard', _pasteFromClipboard, const Color(0xFF10B981)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // JSON Editor Box
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _jsonController,
              maxLines: 12,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Paste or edit Grammar, Vocabulary or Kanji JSON here...',
                border: InputBorder.none,
              ),
              onChanged: _validateJson,
            ),
          ),
          const SizedBox(height: 12),

          // Parsing error
          if (_parseError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Text(
                _parseError!,
                style: GoogleFonts.fredoka(fontSize: 12, color: const Color(0xFFEF4444)),
              ),
            ),

          // Preview Card if valid
          if (hasValidPayload) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Valid ${_detectedType.toUpperCase()} Schema Detected!',
                        style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getPreviewSummary(),
                    style: GoogleFonts.fredoka(fontSize: 12, color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isSaving ? 'Publishing...' : 'Publish ${_detectedType.toUpperCase()} Topic',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                ),
                onPressed: _isSaving ? null : _uploadAndSave,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Manage Existing Topics Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Published Lessons',
                style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              Row(
                children: [
                  _buildManageTabChip('Grammar (${db.topics.length})', 0),
                  const SizedBox(width: 6),
                  _buildManageTabChip('Vocab (${db.vocabTopics.length})', 1),
                  const SizedBox(width: 6),
                  _buildManageTabChip('Kanji (${db.kanjiTopics.length})', 2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_manageTab == 0)
            ...db.topics.map((t) => _buildManageItemCard(
              title: t.title,
              sub: 'JLPT ${t.jlpt} • ${t.questions.length} questions • ID: ${t.id}',
              color: const Color(0xFF6366F1),
              onEdit: () {
                final encoded = const JsonEncoder.withIndent('  ').convert(t.toMap());
                _jsonController.text = encoded;
                _validateJson(encoded);
              },
              onDelete: () => db.deleteTopic(t.id),
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ))
          else if (_manageTab == 1)
            ...db.vocabTopics.map((t) => _buildManageItemCard(
              title: t.title,
              sub: 'JLPT ${t.jlpt} • ${t.vocabulary.length} words • ID: ${t.id}',
              color: const Color(0xFF06B6D4),
              onEdit: () {
                final encoded = const JsonEncoder.withIndent('  ').convert(t.toMap());
                _jsonController.text = encoded;
                _validateJson(encoded);
              },
              onDelete: () => db.deleteVocabTopic(t.id),
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
            ))
          else
            ...db.kanjiTopics.map((t) => _buildManageItemCard(
              title: t.title,
              sub: 'JLPT ${t.jlpt} • ${t.kanji.length} kanji • ID: ${t.id}',
              color: const Color(0xFF8B5CF6),
              onEdit: () {
                final encoded = const JsonEncoder.withIndent('  ').convert(t.toMap());
                _jsonController.text = encoded;
                _validateJson(encoded);
              },
              onDelete: () => db.deleteKanjiTopic(t.id),
              cardColor: cardColor,
              textColor: textColor,
              subtextColor: subtextColor,
            )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getPreviewSummary() {
    if (_parsedVocabTopic != null) {
      return 'Title: ${_parsedVocabTopic!.title} • Level: ${_parsedVocabTopic!.jlpt} • Words: ${_parsedVocabTopic!.vocabulary.length}';
    }
    if (_parsedKanjiTopic != null) {
      return 'Title: ${_parsedKanjiTopic!.title} • Level: ${_parsedKanjiTopic!.jlpt} • Kanji: ${_parsedKanjiTopic!.kanji.length}';
    }
    if (_parsedGrammarTopic != null) {
      return 'Title: ${_parsedGrammarTopic!.title} • Level: ${_parsedGrammarTopic!.jlpt} • Questions: ${_parsedGrammarTopic!.questions.length}';
    }
    return '';
  }

  Widget _buildTemplateBtn(String label, VoidCallback onTap, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      child: Text(label, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildManageTabChip(String label, int index) {
    final isSelected = _manageTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _manageTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildManageItemCard({
    required String title,
    required String sub,
    required Color color,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 38,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                Text(sub, style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
            tooltip: 'Load into Studio',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Delete Topic',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
