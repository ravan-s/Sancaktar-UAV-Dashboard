// lib/services/system_tts_stub.dart
// Web ve desteklenmeyen platformlar için boş TTS implementasyonu

class VoiceAssistant {
  Future<void> speakViaSystem(String text) async {
    // Stub: bu platformda TTS desteklenmiyor
  }

  Future<void> stop() async {}

  void dispose() {}
}
