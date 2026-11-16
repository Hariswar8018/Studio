import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsEngine {
  local,
  azure,
}

class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._internal();
  static TtsService get instance => _instance;
  factory TtsService() => _instance;

  TtsService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  TtsEngine _engine = TtsEngine.local;
  TtsEngine get engine => _engine;
  bool get isAzure => _engine == TtsEngine.azure;

  double _speechRate = 0.9;
  double get speechRate => _speechRate;

  double _pitch = 1.0;
  double get pitch => _pitch;

  String _selectedLocalVoice = '';
  String get selectedLocalVoice => _selectedLocalVoice;

  List<Map<String, String>> _localJapaneseVoices = [];
  List<Map<String, String>> get localJapaneseVoices => _localJapaneseVoices;

  final String _selectedVoicevoxUrl = 'https://voicevox.suwatte.org';

  String _azureKey = '';
  String _azureRegion = 'japaneast';
  String _azureVoice = 'ja-JP-NanamiNeural';

  String get azureKey => _azureKey;
  String get azureRegion => _azureRegion;
  String get azureVoice => _azureVoice;
  bool get hasAzureKey => _azureKey.trim().isNotEmpty;

  static const List<Map<String, String>> availableAzureVoices = [
    {'name': 'ja-JP-NanamiNeural', 'label': 'Nanami (Female, Warm & Natural)', 'gender': 'female'},
    {'name': 'ja-JP-AoiNeural', 'label': 'Aoi (Female, Bright & Clear)', 'gender': 'female'},
    {'name': 'ja-JP-MayuNeural', 'label': 'Mayu (Female, Casual)', 'gender': 'female'},
    {'name': 'ja-JP-ShioriNeural', 'label': 'Shiori (Female, Polite & Gentle)', 'gender': 'female'},
    {'name': 'ja-JP-KeitaNeural', 'label': 'Keita (Male, Natural & Confident)', 'gender': 'male'},
    {'name': 'ja-JP-DaichiNeural', 'label': 'Daichi (Male, Deep & Academic)', 'gender': 'male'},
    {'name': 'ja-JP-NaokiNeural', 'label': 'Naoki (Male, Youthful & Dynamic)', 'gender': 'male'},
  ];

  Future<void> init() async {
    await _initTts();
  }

  Future<void> _initTts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEngine = prefs.getString('selected_tts_engine');
      if (savedEngine == 'azure') {
        _engine = TtsEngine.azure;
      } else {
        _engine = TtsEngine.local;
      }

      _azureKey = prefs.getString('azure_speech_key') ?? '';
      _azureRegion = prefs.getString('azure_speech_region') ?? 'japaneast';
      _azureVoice = prefs.getString('azure_speech_voice') ?? 'ja-JP-NanamiNeural';
      _speechRate = prefs.getDouble('saved_tts_speech_rate') ?? 0.9;
      _pitch = prefs.getDouble('saved_tts_pitch') ?? 1.0;
      _selectedLocalVoice = prefs.getString('saved_local_voice') ?? '';

      await _flutterTts.setLanguage('ja-JP');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('Flutter TTS Error: $msg');
        _isPlaying = false;
        notifyListeners();
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        notifyListeners();
      });

      // Query available local voices
      try {
        final dynamic voices = await _flutterTts.getVoices;
        if (voices is List) {
          _localJapaneseVoices = voices
              .where((v) {
                final locale = v['locale']?.toString().toLowerCase() ?? '';
                final name = v['name']?.toString().toLowerCase() ?? '';
                return locale.contains('ja') || name.contains('ja') || name.contains('japan');
              })
              .map<Map<String, String>>((v) => {
                    'name': v['name']?.toString() ?? '',
                    'locale': v['locale']?.toString() ?? '',
                  })
              .toList();

          if (_selectedLocalVoice.isNotEmpty) {
            await _flutterTts.setVoice({'name': _selectedLocalVoice, 'locale': 'ja-JP'});
          }
        }
      } catch (e) {
        debugPrint('Error loading local TTS voices: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> setEngine(TtsEngine newEngine) async {
    _engine = newEngine;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_tts_engine', newEngine.name);
    notifyListeners();
  }

  Future<void> setPitch(double newPitch) async {
    _pitch = newPitch;
    await _flutterTts.setPitch(newPitch);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_tts_pitch', newPitch);
    notifyListeners();
  }

  Future<void> setLocalVoice(String voiceName) async {
    _selectedLocalVoice = voiceName;
    if (voiceName.isNotEmpty) {
      await _flutterTts.setVoice({'name': voiceName, 'locale': 'ja-JP'});
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_local_voice', voiceName);
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate;
    _flutterTts.setSpeechRate(rate);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('saved_tts_speech_rate', rate);
    });
    notifyListeners();
  }

  void setRate(double rate) => setSpeechRate(rate);

  Future<void> speak(String text) => speakJapanese(text);

  Future<void> speakJapanese(String text, {String? customVoice}) async {
    if (text.trim().isEmpty) return;

    _isPlaying = true;
    notifyListeners();

    // 1. If Azure Engine is selected, try Azure Speech synthesis
    if (_engine == TtsEngine.azure) {
      if (_azureKey.isNotEmpty) {
        try {
          await _flutterTts.stop();
          await _audioPlayer.stop();

          final voiceToUse = customVoice ?? _azureVoice;
          final audioBytes = await _synthesizeAzure(text, voiceToUse);
          if (audioBytes.isNotEmpty) {
            await _audioPlayer.play(BytesSource(audioBytes));
            return;
          }
        } catch (e) {
          debugPrint('Azure Speech failed, falling back to local TTS: $e');
        }
      }

      // If Azure key is not present or failed, attempt VOICEVOX studio fallback
      try {
        final queryUrl = Uri.parse('$_selectedVoicevoxUrl/audio_query?text=${Uri.encodeComponent(text)}&speaker=3');
        final queryRes = await http.post(queryUrl).timeout(const Duration(seconds: 4));

        if (queryRes.statusCode == 200) {
          final synthUrl = Uri.parse('$_selectedVoicevoxUrl/synthesis?speaker=3');
          final synthRes = await http.post(
            synthUrl,
            headers: {'Content-Type': 'application/json'},
            body: queryRes.body,
          ).timeout(const Duration(seconds: 6));

          if (synthRes.statusCode == 200 && synthRes.bodyBytes.isNotEmpty) {
            await _audioPlayer.play(BytesSource(synthRes.bodyBytes));
            return;
          }
        }
      } catch (vErr) {
        debugPrint('VOICEVOX synthesis error: $vErr');
      }
    }

    // 2. Local Flutter TTS engine (device system TTS)
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop();

      final res = await _flutterTts.speak(text);
      if (res == 1) {
        return;
      }
    } catch (e) {
      debugPrint('Local Flutter TTS failed: $e');
    }

    _isPlaying = false;
    notifyListeners();
  }

  Future<Uint8List> _synthesizeAzure(String text, String voiceName) async {
    final url = Uri.parse('https://$_azureRegion.tts.speech.microsoft.com/cognitiveservices/v1');

    final safeText = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    final ssml = '''<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='ja-JP'>
  <voice name='$voiceName'>
    <prosody pitch='+0Hz' rate='${_speechRate.toStringAsFixed(2)}'>
      $safeText
    </prosody>
  </voice>
</speak>''';

    final headers = {
      'Ocp-Apim-Subscription-Key': _azureKey,
      'Content-Type': 'application/ssml+xml',
      'X-Microsoft-OutputFormat': 'audio-24khz-96kbitrate-mono-mp3',
      'User-Agent': 'LangNovaJLPT',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: utf8.encode(ssml),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Azure Speech HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      await _audioPlayer.stop();
    } catch (_) {}
    _isPlaying = false;
    notifyListeners();
  }
}
