import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String _locale = 'ar_EG';
  double _volume = 1.0;
  double _pitch = 1.0;
  double _speechRate = 0.5;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    try {
      await _tts.setLanguage(_locale);
      await _tts.setVolume(_volume);
      await _tts.setPitch(_pitch);
      await _tts.setSpeechRate(_speechRate);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    
    await _tts.setLanguage(_locale);
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _tts.setVolume(_volume);
  }

  void setPitch(double pitch) {
    _pitch = pitch.clamp(0.5, 2.0);
    _tts.setPitch(_pitch);
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.1, 1.0);
    _tts.setSpeechRate(_speechRate);
  }

  void setLocale(String locale) {
    _locale = locale;
    _tts.setLanguage(_locale);
  }

  Future<List<dynamic>> getLanguages() async {
    return await _tts.getLanguages;
  }

  Future<bool> isLanguageAvailable(String locale) async {
    return await _tts.isLanguageAvailable(locale);
  }

  void dispose() {
    _tts.stop();
  }
}