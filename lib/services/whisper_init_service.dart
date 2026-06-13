import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_kit/download_model.dart';

class WhisperInitService {
  WhisperInitService._();
  static final instance = WhisperInitService._();

  bool _ready = false;
  bool _initializing = false;

  bool get isReady => _ready;
  bool get isInitializing => _initializing;

  Future<void> warmUp() async {
    if (_ready || _initializing) return;
    _initializing = true;

    try {
      final dir = await getApplicationSupportDirectory();
      await downloadModel(
        model: WhisperModel.tiny,
        destinationPath: dir.path,
      );
      _ready = true;
      debugPrint('✅ Whisper tiny model downloaded and ready');
    } catch (e) {
      // Download failed — will be retried on first actual transcribe
      debugPrint('❌ Whisper model pre-download error: $e');
    } finally {
      _initializing = false;
    }
  }
}
