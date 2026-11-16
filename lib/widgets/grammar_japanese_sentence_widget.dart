import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'tokenized_japanese_text.dart';

class GrammarJapaneseSentenceWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool showFurigana;
  final bool isVibrant;

  // Static in-memory cache to prevent repeated async regex execution across widget rebuilds
  static final Map<String, TransliterationData> _cache = {};
  static final Map<String, Future<TransliterationData>> _futureCache = {};

  const GrammarJapaneseSentenceWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
    this.showFurigana = true,
    this.isVibrant = true,
  });

  Widget _buildContent(TransliterationData data, TextStyle baseStyle) {
    if (showFurigana) {
      final hiragana = data.hiragana.trim();
      final romaji = data.romaji.trim();
      final List<String> parts = [];
      if (hiragana.isNotEmpty && hiragana != text.trim()) {
        parts.add(hiragana);
      }
      if (romaji.isNotEmpty && romaji != text.trim()) {
        parts.add(romaji);
      }
      if (parts.isEmpty && romaji.isNotEmpty) {
        parts.add(romaji);
      }
      final furiganaHeader = parts.join(' • ');

      return Column(
        crossAxisAlignment: textAlign == TextAlign.center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (furiganaHeader.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                furiganaHeader,
                textAlign: textAlign,
                style: GoogleFonts.fredoka(
                  fontSize: ((style?.fontSize ?? 20) * 0.6).clamp(11.0, 15.0),
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          TokenizedJapaneseText(
            text: text,
            style: baseStyle,
            textAlign: textAlign,
            isVibrant: isVibrant,
          ),
        ],
      );
    } else {
      return TokenizedJapaneseText(
        text: text,
        style: baseStyle,
        textAlign: textAlign,
        isVibrant: isVibrant,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final baseStyle = style ?? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

    // Fast path: if furigana disabled, just render tokenized
    if (!showFurigana) {
      return TokenizedJapaneseText(
        text: text,
        style: baseStyle,
        textAlign: textAlign,
        isVibrant: isVibrant,
      );
    }

    // Check if text contains Japanese characters (Hiragana, Katakana, or Kanji)
    final hasJapanese = text.runes.any((r) =>
        (r >= 0x3040 && r <= 0x309F) || // Hiragana
        (r >= 0x30A0 && r <= 0x30FF) || // Katakana
        (r >= 0x4E00 && r <= 0x9FAF));  // Kanji

    if (!hasJapanese) {
      return TokenizedJapaneseText(
        text: text,
        style: baseStyle,
        textAlign: textAlign,
        isVibrant: isVibrant,
      );
    }

    // Memory cache fast path
    if (_cache.containsKey(text)) {
      return _buildContent(_cache[text]!, baseStyle);
    }

    // Deduplicated future cache
    final future = _futureCache.putIfAbsent(
      text,
      () => JpTransliterate.transliterate(kanji: text).then((data) {
        _cache[text] = data;
        return data;
      }).catchError((e) {
        debugPrint('JpTransliterate error for "$text": $e');
        final fallback = TransliterationData(
          kanji: text,
          romaji: '',
          hiragana: '',
          katakana: '',
        );
        _cache[text] = fallback;
        return fallback;
      }),
    );

    return FutureBuilder<TransliterationData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildContent(snapshot.data!, baseStyle);
        }
        return TokenizedJapaneseText(
          text: text,
          style: baseStyle,
          textAlign: textAlign,
          isVibrant: isVibrant,
        );
      },
    );
  }
}
