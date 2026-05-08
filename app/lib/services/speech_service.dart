import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/keywords.dart';

typedef SpeakingCallback = void Function(bool);
typedef KeywordCallback = void Function(String);
typedef TranscriptCallback = void Function(String);
typedef PopCallback = void Function();
typedef SendCallback = void Function(String);
typedef StartCallback = void Function();

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool available = false;
  bool restarting = false;
  DateTime _lastRestart = DateTime.now();

  SpeakingCallback? onSpeaking;
  KeywordCallback? onKeyword;
  TranscriptCallback? onTranscript;
  PopCallback? onPopAnimation;
  SendCallback? onSend;
  StartCallback? onStart;
  void Function()? onError;

  Future<bool> init() async {
    available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          restarting = false;
          Future.delayed(const Duration(milliseconds: 250), () => onStart?.call());
        }
      },
      onError: (e) {
        if (ignoredSpeechErrors.contains(e.errorMsg)) {
          restarting = false;
          Future.delayed(const Duration(milliseconds: 350), () => onStart?.call());
          return;
        }
        restarting = false;
        onSpeaking?.call(false);
      },
    );
    return available;
  }

  void start() {
    if (!available || _speech.isListening) return;
    final now = DateTime.now();
    if (restarting || now.difference(_lastRestart).inMilliseconds < 2000) return;
    restarting = true;

    _speech.listen(
      localeId: 'ar_EG',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (result) {
        final words = result.recognizedWords.trim();
        final speaking = words.isNotEmpty && !result.finalResult;

        onSpeaking?.call(speaking);

        if (!result.finalResult) return;

        restarting = false;
        _lastRestart = DateTime.now();
        onSpeaking?.call(false);

        if (words.isEmpty) return;

        final keyword = extractKeyword(words);
        onTranscript?.call(words);
        onKeyword?.call(keyword ?? '؟');
        onPopAnimation?.call();
        onSend?.call(keyword ?? '');
      },
    ).then((_) {
      restarting = false;
      _lastRestart = DateTime.now();
      onStart?.call();
    }).catchError((_) {
      restarting = false;
      _lastRestart = DateTime.now();
      onStart?.call();
    });
  }

  void stop() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}