import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  String _locale = 'ar_EG';

  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    try {
      return await _speech.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
    } catch (e) {
      debugPrint('STT init failed: $e');
      return false;
    }
  }

  Future<void> startListening({
    Function(String)? onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (_isListening) return;

    final available = await _speech.initialize();
    if (!available) {
      debugPrint('STT not available');
      return;
    }

    _isListening = true;
    _lastWords = '';

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        if (onResult != null) {
          onResult(_lastWords);
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 5),
        localeId: _locale,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  Future<void> cancel() async {
    await _speech.cancel();
    _isListening = false;
  }

  void setLocale(String locale) {
    _locale = locale;
  }

  Future<List<LocaleName>> get locales => _speech.locales();

  void dispose() {
    _speech.stop();
  }
}
