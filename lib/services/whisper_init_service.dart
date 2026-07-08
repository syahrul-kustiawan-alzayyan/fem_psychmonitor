import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_kit/download_model.dart';

class WhisperInitService {
  WhisperInitService._();
  static final instance = WhisperInitService._();

  bool _ready = false;
  bool _initializing = false;
  double _progress = 0.0;
  String _statusMessage = '';

  bool get isReady => _ready;
  bool get isInitializing => _initializing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  final List<void Function(double progress, String message)> _listeners = [];

  void addProgressListener(void Function(double progress, String message) listener) {
    _listeners.add(listener);
  }

  void removeProgressListener(void Function(double progress, String message) listener) {
    _listeners.remove(listener);
  }

  void _notify(double progress, String message) {
    _progress = progress;
    _statusMessage = message;
    for (final listener in _listeners) {
      listener(progress, message);
    }
  }

  Future<void> warmUp() async {
    if (_ready) return;
    if (_initializing) {
      // Already downloading, wait until done
      await Future.doWhile(() => Future.delayed(const Duration(milliseconds: 200), () => _initializing && !_ready));
      return;
    }
    _initializing = true;

    try {
      _notify(0.0, 'Memeriksa model...');
      final dir = await getApplicationSupportDirectory();

      // Check if model already exists
      final modelFile = File(WhisperModel.base.getPath(dir.path));
      if (modelFile.existsSync()) {
        _ready = true;
        _notify(1.0, 'Model sudah tersedia');
        debugPrint('✅ Whisper base model already exists');
        return;
      }

      _notify(0.05, 'Mengunduh model suara (~150MB)...');
      await downloadModel(
        model: WhisperModel.base,
        destinationPath: dir.path,
        onDownloadProgress: (received, total) {
          final pct = received / total;
          _notify(pct, 'Mengunduh model... ${(pct * 100).toStringAsFixed(0)}%');
        },
      );
      _ready = true;
      _notify(1.0, 'Model siap digunakan');
      debugPrint('✅ Whisper base model downloaded and ready');
    } catch (e) {
      _notify(0.0, 'Internet diperlukan untuk mengunduh model suara');
      debugPrint('❌ Whisper model pre-download error: $e');
    } finally {
      _initializing = false;
    }
  }
}
