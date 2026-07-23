import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_kit/download_model.dart';

class WhisperInitService {
  WhisperInitService._();
  static final instance = WhisperInitService._();

  bool _initializing = false;
  bool _baseReady = false;
  bool _tinyReady = false;
  double _progress = 0.0;
  String _statusMessage = '';

  bool get isReady => _baseReady;
  bool get isBaseReady => _baseReady;
  bool get isTinyReady => _tinyReady;
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
    if (_initializing) {
      await Future.doWhile(() => Future.delayed(const Duration(milliseconds: 200), () => _initializing));
      return;
    }
    _initializing = true;

    try {
      await _ensureModel(WhisperModel.base, 'Base', 0.0, 0.5);
      await _ensureModel(WhisperModel.tiny, 'Tiny', 0.5, 1.0);
    } catch (e) {
      _notify(0.0, 'Internet diperlukan untuk mengunduh model suara');
      debugPrint('❌ Whisper model pre-download error: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<void> _ensureModel(WhisperModel model, String label, double progressStart, double progressEnd) async {
    final dir = await getApplicationSupportDirectory();
    final modelFile = File(model.getPath(dir.path));
    final isBase = model == WhisperModel.base;

    if (modelFile.existsSync()) {
      if (isBase) { _baseReady = true; } else { _tinyReady = true; }
      debugPrint('✅ Whisper $label model already exists');
      return;
    }

    _notify(progressStart, 'Mengunduh model $label...');
    await downloadModel(
      model: model,
      destinationPath: dir.path,
      onDownloadProgress: (received, total) {
        final pct = progressStart + (received / total) * (progressEnd - progressStart);
        _notify(pct, 'Mengunduh model $label... ${(pct * 100).toStringAsFixed(0)}%');
      },
    );

    if (isBase) { _baseReady = true; } else { _tinyReady = true; }
    debugPrint('✅ Whisper $label model downloaded and ready');
  }

  Future<String> getModelPath(WhisperModel model) async {
    final dir = await getApplicationSupportDirectory();
    return model.getPath(dir.path);
  }
}
