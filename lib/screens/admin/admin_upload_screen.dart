import 'dart:convert';
import 'package:file_picker/file_picker.dart';
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
import 'admin_lessons_screen.dart';
import 'admin_reports_screen.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _jsonController = TextEditingController();

  // Detected parsed models for single topic
  GrammarTopicModel? _parsedGrammarTopic;
  VocabularyTopicModel? _parsedVocabTopic;
  KanjiTopicModel? _parsedKanjiTopic;
  String _detectedType = 'grammar'; // 'grammar' | 'vocab' | 'kanji'

  // Picked file info for direct upload & batch import
  ParsedJsonFileInfo? _pickedFileInfo;
  bool _isPickingFile = false;

  String? _parseError;
  bool _isSaving = false;

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

      if (decoded is List) {
        // Multi-topic batch list pasted in editor
        setState(() {
          _detectedType = 'batch (${decoded.length} items)';
          _parsedGrammarTopic = null;
          _parsedVocabTopic = null;
          _parsedKanjiTopic = null;
          _parseError = null;
        });
        return;
      }

      if (decoded is! Map<String, dynamic>) {
        setState(() {
          _parsedGrammarTopic = null;
          _parsedVocabTopic = null;
          _parsedKanjiTopic = null;
          _parseError = 'Root of JSON must be an object { ... } or list [ ... ]';
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

  Future<void> _pickAndProcessJsonFile({String? category}) async {
    setState(() => _isPickingFile = true);
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFiles.isEmpty) {
        setState(() => _isPickingFile = false);
        return;
      }

      final file = pickedFiles.first;
      final rawBytes = await file.readAsBytes();
      final content = utf8.decode(rawBytes);

      if (content.trim().isEmpty) {
        throw 'The selected JSON file is empty.';
      }

      final dynamic decoded = jsonDecode(content.trim());
      final grammarList = <GrammarTopicModel>[];
      final vocabList = <VocabularyTopicModel>[];
      final kanjiList = <KanjiTopicModel>[];

      void processItem(dynamic item) {
        if (item is! Map<String, dynamic>) {
          if (item is Map) {
            item = Map<String, dynamic>.from(item);
          } else {
            return;
          }
        }

        final section = item['section']?.toString().toLowerCase() ?? '';
        final forced = category?.toLowerCase();

        if (forced == 'vocab' || section == 'vocabulary' || section == 'vocab' || item.containsKey('vocabulary')) {
          vocabList.add(VocabularyTopicModel.fromMap(item));
        } else if (forced == 'kanji' || section == 'kanji' || item.containsKey('kanji') || item.containsKey('characters')) {
          kanjiList.add(KanjiTopicModel.fromMap(item));
        } else {
          grammarList.add(GrammarTopicModel.fromMap(item));
        }
      }

      if (decoded is List) {
        for (final elem in decoded) {
          processItem(elem);
        }
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('topics') && decoded['topics'] is List) {
          for (final elem in decoded['topics']) {
            processItem(elem);
          }
        } else if (decoded.containsKey('lessons') && decoded['lessons'] is List) {
          for (final elem in decoded['lessons']) {
            processItem(elem);
          }
        } else {
          processItem(decoded);
        }
      } else {
        throw 'Invalid JSON structure: Root must be an Object or Array.';
      }

      final total = grammarList.length + vocabList.length + kanjiList.length;
      if (total == 0) {
        throw 'No valid Grammar, Vocabulary, or Kanji topics found in the file.';
      }

      final fileInfo = ParsedJsonFileInfo(
        fileName: file.name,
        fileSize: rawBytes.length,
        rawContent: content,
        grammarTopics: grammarList,
        vocabTopics: vocabList,
        kanjiTopics: kanjiList,
        categoryHint: category ?? 'auto',
      );

      setState(() {
        _pickedFileInfo = fileInfo;
        if (total == 1) {
          _jsonController.text = const JsonEncoder.withIndent('  ').convert(jsonDecode(content.trim()));
          _validateJson(_jsonController.text);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loaded "${file.name}": ${fileInfo.summaryText}!',
              style: GoogleFonts.fredoka(),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text('JSON File Error', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Could not process JSON file:\n\n$e',
              style: GoogleFonts.fredoka(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _publishPickedFile() async {
    if (_pickedFileInfo == null) return;
    final info = _pickedFileInfo!;
    final db = Provider.of<DatabaseService>(context, listen: false);

    setState(() => _isSaving = true);
    try {
      if (info.grammarTopics.isNotEmpty) {
        await db.saveGrammarTopicsBatch(info.grammarTopics);
      }
      if (info.vocabTopics.isNotEmpty) {
        await db.saveVocabTopicsBatch(info.vocabTopics);
      }
      if (info.kanjiTopics.isNotEmpty) {
        await db.saveKanjiTopicsBatch(info.kanjiTopics);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text('Publish Successful!', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Successfully published ${info.totalTopics} lesson topic(s) to the database:\n• ${info.summaryText}\n\nLessons are immediately live and active in the app.',
              style: GoogleFonts.fredoka(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Great!'),
              ),
            ],
          ),
        );
      }

      setState(() {
        _pickedFileInfo = null;
        _jsonController.clear();
        _parsedGrammarTopic = null;
        _parsedVocabTopic = null;
        _parsedKanjiTopic = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish topics: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _loadPickedFileIntoEditor() {
    if (_pickedFileInfo == null) return;
    try {
      final formatted = const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(_pickedFileInfo!.rawContent.trim()));
      _jsonController.text = formatted;
      _validateJson(formatted);
    } catch (_) {
      _jsonController.text = _pickedFileInfo!.rawContent;
      _validateJson(_pickedFileInfo!.rawContent);
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
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.flag_rounded, color: Color(0xFFEF4444)),
                Consumer<DatabaseService>(
                  builder: (context, db, _) {
                    if (db.pendingReportsCount == 0) return const SizedBox.shrink();
                    return Positioned(
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
                    );
                  },
                ),
              ],
            ),
            tooltip: 'View Question Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 16),
              label: Text('Lessons', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLessonsScreen()),
                );
              },
            ),
          ),
        ],
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
          const SizedBox(height: 16),

          // ================= DIRECT FILE UPLOAD SECTION =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_upload_outlined, color: Color(0xFF6366F1), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload JSON File Directly',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Pick .json files to publish or inspect in Grammar, Kanji, or Vocabulary',
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4 Category Upload Buttons Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildUploadActionChip(
                      icon: Icons.menu_book_rounded,
                      label: 'Upload Grammar JSON',
                      color: const Color(0xFF6366F1),
                      onTap: _isPickingFile ? null : () => _pickAndProcessJsonFile(category: 'grammar'),
                    ),
                    _buildUploadActionChip(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Upload Vocab JSON',
                      color: const Color(0xFF06B6D4),
                      onTap: _isPickingFile ? null : () => _pickAndProcessJsonFile(category: 'vocab'),
                    ),
                    _buildUploadActionChip(
                      icon: Icons.edit_outlined,
                      label: 'Upload Kanji JSON',
                      color: const Color(0xFF8B5CF6),
                      onTap: _isPickingFile ? null : () => _pickAndProcessJsonFile(category: 'kanji'),
                    ),
                    _buildUploadActionChip(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Auto-Detect File',
                      color: const Color(0xFF10B981),
                      onTap: _isPickingFile ? null : () => _pickAndProcessJsonFile(),
                    ),
                  ],
                ),

                if (_isPickingFile) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(color: Color(0xFF6366F1)),
                ],

                // Picked File Card Banner
                if (_pickedFileInfo != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_rounded, color: Color(0xFF10B981), size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFileInfo!.fileName,
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Size: ${(_pickedFileInfo!.fileSize / 1024).toStringAsFixed(1)} KB • ${_pickedFileInfo!.summaryText}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      color: const Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              tooltip: 'Clear Selected File',
                              onPressed: () => setState(() => _pickedFileInfo = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.cloud_upload_rounded, size: 18),
                                label: Text(
                                  _isSaving
                                      ? 'Publishing...'
                                      : 'Direct Publish (${_pickedFileInfo!.totalTopics})',
                                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: _isSaving ? null : _publishPickedFile,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1),
                                  side: const BorderSide(color: Color(0xFF6366F1)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.code_rounded, size: 18),
                                label: Text(
                                  'View in Editor',
                                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                onPressed: _loadPickedFileIntoEditor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Template Loaders Row
          Text(
            'Load Sample Templates & Paste:',
            style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTemplateBtn('📁 Pick File', () => _pickAndProcessJsonFile(), const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
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

          // Option "Lessons" navigation card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lessons Management',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View stats by level, search, inspect full lessons & rename',
                        style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text('Open', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminLessonsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

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

  Widget _buildUploadActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      onPressed: onTap,
    );
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
}

class ParsedJsonFileInfo {
  final String fileName;
  final int fileSize;
  final String rawContent;
  final List<GrammarTopicModel> grammarTopics;
  final List<VocabularyTopicModel> vocabTopics;
  final List<KanjiTopicModel> kanjiTopics;
  final String categoryHint;

  ParsedJsonFileInfo({
    required this.fileName,
    required this.fileSize,
    required this.rawContent,
    required this.grammarTopics,
    required this.vocabTopics,
    required this.kanjiTopics,
    required this.categoryHint,
  });

  int get totalTopics => grammarTopics.length + vocabTopics.length + kanjiTopics.length;

  String get summaryText {
    final parts = <String>[];
    if (grammarTopics.isNotEmpty) parts.add('${grammarTopics.length} Grammar');
    if (vocabTopics.isNotEmpty) parts.add('${vocabTopics.length} Vocab');
    if (kanjiTopics.isNotEmpty) parts.add('${kanjiTopics.length} Kanji');
    return parts.join(' • ');
  }
}
