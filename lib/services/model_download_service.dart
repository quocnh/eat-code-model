import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelDownloadService {
  // Singleton
  static final ModelDownloadService _instance =
      ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._internal();

  // flutter_gemma always loads from a file named 'model.bin' in the app documents directory.
  // Upload your model to Firebase Storage (or any public CDN) and paste the URL below.
  static const String modelFileName = 'model.bin';
  static const String modelUrl =
      'https://github.com/quocnh/eat-code-model/releases/download/v1.0-model/gemma-2b-it-gpu-int4.bin';
  static const int modelSizeMb = 800; // approximate

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  /// Returns the full path where the model should be stored
  Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$modelFileName';
  }

  /// Returns true if the model file exists on disk
  Future<bool> isModelDownloaded() async {
    final path = await modelPath;
    return File(path).existsSync();
  }

  /// Returns file size in MB if downloaded, else null
  Future<double?> downloadedSizeMb() async {
    final path = await modelPath;
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Downloads the model with progress callback.
  /// [onProgress] is called with values 0.0 to 1.0.
  /// [onComplete] is called on success.
  /// [onError] is called with error message on failure.
  Future<void> downloadModel({
    required void Function(double progress) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    if (_isDownloading) return;
    _isDownloading = true;
    _downloadProgress = 0.0;

    try {
      final path = await modelPath;
      final file = File(path);

      // Create a fresh HTTP request
      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final contentLength =
          response.contentLength ?? (modelSizeMb * 1024 * 1024);
      var received = 0;

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        _downloadProgress = received / contentLength;
        onProgress(_downloadProgress);
      }
      await sink.flush();
      await sink.close();

      _isDownloading = false;
      _downloadProgress = 1.0;
      onComplete();
    } catch (e) {
      _isDownloading = false;
      _downloadProgress = 0.0;
      // Clean up partial file
      try {
        final path = await modelPath;
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
      onError(e.toString());
    }
  }

  /// Deletes the model to free up storage space
  Future<void> deleteModel() async {
    final path = await modelPath;
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Cancel in-progress download by aborting (sets flag; caller should handle UI)
  void cancelDownload() {
    // Note: http.Client doesn't have built-in cancel on all platforms.
    // We set the flag and let the stream error naturally when the client is closed.
    _isDownloading = false;
    _downloadProgress = 0.0;
  }
}
