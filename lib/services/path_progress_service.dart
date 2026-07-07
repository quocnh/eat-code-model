import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Tracks which technique IDs the user has visited.
/// Progress is persisted to a JSON file in the app documents directory
/// so it survives app restarts.
class PathProgressService {
  static final PathProgressService _instance = PathProgressService._();
  factory PathProgressService() => _instance;
  PathProgressService._();

  final Set<String> _visited = {};
  File? _file;
  bool _initialized = false;

  /// Must be called once at app startup (before routing to home).
  /// Loads previously saved progress from disk.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/path_progress.json');
      if (await _file!.exists()) {
        final contents = await _file!.readAsString();
        final List<dynamic> ids = jsonDecode(contents) as List<dynamic>;
        _visited.addAll(ids.cast<String>());
        debugPrint('[PathProgressService] loaded ${_visited.length} visited IDs');
      }
    } catch (e) {
      debugPrint('[PathProgressService] init error: $e');
    }
    _initialized = true;
  }

  void markVisited(String techniqueId) {
    if (_visited.add(techniqueId)) {
      _persist(); // fire-and-forget
    }
  }

  bool isVisited(String techniqueId) => _visited.contains(techniqueId);

  /// Returns how many IDs from [techniqueIds] have been visited.
  int countVisited(List<String> techniqueIds) =>
      techniqueIds.where(_visited.contains).length;

  // Writes visited set to disk. Errors are silently logged.
  void _persist() {
    _file?.writeAsString(jsonEncode(_visited.toList())).catchError((Object e) {
      debugPrint('[PathProgressService] persist error: $e');
      return _file!;
    });
  }
}
