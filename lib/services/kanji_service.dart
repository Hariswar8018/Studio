import 'package:flutter/foundation.dart';
import 'package:flutter_kanjivg/flutter_kanjivg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KanjiService {
  static final KanjiService instance = KanjiService._internal();
  factory KanjiService() => instance;
  KanjiService._internal();

  static const String _jsdelivrBase = 'https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji';
  static const String _githubBase = 'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji';

  final Map<String, KvgData> _memoryCache = {};

  /// Check whether a single character is a CJK Unified Ideograph (Kanji)
  static bool isKanji(String char) {
    if (char.isEmpty) return false;
    final code = char.runes.first;
    return (code >= 0x4E00 && code <= 0x9FAF) || (code >= 0x3400 && code <= 0x4DBF);
  }

  /// Extract all unique Kanji characters from a word or sentence in order of occurrence
  static List<String> extractKanjiChars(String text) {
    final List<String> result = [];
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (isKanji(ch) && !result.contains(ch)) {
        result.add(ch);
      }
    }
    return result;
  }

  /// Get 5-digit lowercase hex string for a character (e.g. '木' -> '06728')
  static String getKanjiHex(String char) {
    if (char.isEmpty) return '';
    return char.runes.first.toRadixString(16).padLeft(5, '0').toLowerCase();
  }

  /// Fetch and parse KanjiVG data for a given character with two-level caching (memory + local disk)
  Future<KvgData?> getKanjiData(String char) async {
    if (char.isEmpty) return null;
    final singleChar = String.fromCharCode(char.runes.first);
    if (!isKanji(singleChar)) return null;

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(singleChar)) {
      return _memoryCache[singleChar];
    }

    final hex = getKanjiHex(singleChar);
    final cacheKey = 'kanjivg_svg_$hex';

    // 2. Check persistent disk cache (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSvg = prefs.getString(cacheKey);
      if (cachedSvg != null && cachedSvg.isNotEmpty) {
        final parsed = const KanjiParser().parse(cachedSvg);
        _memoryCache[singleChar] = parsed;
        return parsed;
      }
    } catch (e) {
      debugPrint("KanjiService cache read error: $e");
    }

    // 3. Fetch from jsDelivr CDN
    String? svgContent = await _fetchFromUrl('$_jsdelivrBase/$hex.svg');

    // 4. Fallback to GitHub raw if jsDelivr fails
    svgContent ??= await _fetchFromUrl('$_githubBase/$hex.svg');

    if (svgContent != null && svgContent.isNotEmpty) {
      try {
        final parsed = const KanjiParser().parse(svgContent);
        _memoryCache[singleChar] = parsed;

        // Persist to disk cache
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, svgContent);
        } catch (_) {}

        return parsed;
      } catch (e) {
        debugPrint("Error parsing KanjiVG SVG for $singleChar ($hex): $e");
      }
    }

    return null;
  }

  Future<String?> _fetchFromUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return res.body;
      }
    } catch (e) {
      debugPrint("KanjiService HTTP fetch error ($url): $e");
    }
    return null;
  }
}

