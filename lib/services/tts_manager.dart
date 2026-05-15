import 'package:flutter_tts/flutter_tts.dart';

class TtsManager {
  TtsManager._();

  static final TtsManager instance = TtsManager._();

  final Set<FlutterTts> _activeTts = {};

  void register(FlutterTts tts) {
    _activeTts.add(tts);
  }

  void unregister(FlutterTts tts) {
    _activeTts.remove(tts);
  }

  Future<void> stopAll() async {
    for (final tts in _activeTts.toList()) {
      try {
        await tts.stop();
      } catch (_) {
        // ignore
      }
    }
  }
}
