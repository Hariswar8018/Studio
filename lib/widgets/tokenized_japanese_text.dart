import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:japanese_word_tokenizer/japanese_word_tokenizer.dart' as jwt;

/// A widget that tokenizes Japanese text into individual words using `japanese_word_tokenizer`
/// and displays each token in distinct alternating vibrant or subtle colors.
class TokenizedJapaneseText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;
  final bool isVibrant;

  const TokenizedJapaneseText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.isVibrant = true,
  });

  // Deep dark colors for high contrast in Light mode
  static const List<Color> _vibrantLight = [
    Color(0xFF1E3A8A), // Deep Dark Navy Blue
    Color(0xFF991B1B), // Deep Dark Crimson Red
    Color(0xFF581C87), // Deep Dark Royal Purple
    Color(0xFF065F46), // Deep Dark Forest Green
    Color(0xFF92400E), // Deep Dark Amber Brown
    Color(0xFF831843), // Deep Dark Berry Pink
    Color(0xFF155E75), // Deep Dark Teal Cyan
    Color(0xFF312E81), // Deep Dark Midnight Indigo
  ];

  // Soft light pastel colors for high contrast in Dark mode
  static const List<Color> _vibrantDark = [
    Color(0xFF93C5FD), // Light Pastel Blue
    Color(0xFFFCA5A5), // Light Pastel Coral Red
    Color(0xFFC4B5FD), // Light Pastel Lavender
    Color(0xFF6EE7B7), // Light Pastel Mint Green
    Color(0xFFFDE047), // Light Pastel Warm Yellow
    Color(0xFFF9A8D4), // Light Pastel Soft Pink
    Color(0xFF67E8F9), // Light Pastel Sky Cyan
    Color(0xFFA5B4FC), // Light Pastel Periwinkle
  ];

  // Palette of subtle distinct colors near black for light mode
  static const List<Color> _nearBlackLight = [
    Color(0xFF0F172A), // Slate 900 (deep dark blue-black)
    Color(0xFF1F2937), // Gray 800 (charcoal)
    Color(0xFF334155), // Slate 700 (dark slate)
    Color(0xFF09090B), // Zinc 950 (near black)
    Color(0xFF1C1917), // Stone 900 (dark warm black)
    Color(0xFF1E1B4B), // Indigo 950 (deep dark navy)
    Color(0xFF064E3B), // Emerald 950 (deep dark green-black)
  ];

  // Palette of subtle distinct colors for dark mode (readable soft light tones)
  static const List<Color> _nearWhiteDark = [
    Color(0xFFF8FAFC), // Off-white Slate
    Color(0xFFCBD5E1), // Slate 300
    Color(0xFFE2E8F0), // Slate 200
    Color(0xFF93C5FD), // Soft ice blue
    Color(0xFFA7F3D0), // Soft mint
    Color(0xFFFDE68A), // Soft warm yellow
    Color(0xFFDDD6FE), // Soft lavender
  ];

  static final RegExp _japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorPalette = isVibrant
        ? (isDark ? _vibrantDark : _vibrantLight)
        : (isDark ? _nearWhiteDark : _nearBlackLight);

    List<dynamic> rawTokens;
    try {
      rawTokens = jwt.tokenize(text);
    } catch (_) {
      rawTokens = [text];
    }

    final baseStyle = style ?? GoogleFonts.fredoka();
    final defaultTextColor = baseStyle.color ?? (isDark ? Colors.white70 : const Color(0xFF0F172A));

    final List<InlineSpan> spans = [];
    int colorIdx = 0;
    for (int i = 0; i < rawTokens.length; i++) {
      final token = rawTokens[i].toString();
      final isJapanese = _japaneseRegex.hasMatch(token);

      // Only Japanese characters get colorful tokens; English and punctuation keep standard base color
      final color = isJapanese
          ? colorPalette[(colorIdx++) % colorPalette.length]
          : defaultTextColor;

      spans.add(
        TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: color,
          ),
        ),
      );
    }

    return RichText(
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }
}
