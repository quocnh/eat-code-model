import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Tracks which techniques the user has visited and mastered (passed quiz).
/// Both sets are persisted to a JSON file in the app documents directory.
class PathProgressService {
  static final PathProgressService _instance = PathProgressService._();
  factory PathProgressService() => _instance;
  PathProgressService._();

  final Set<String> _visited = {};
  final Set<String> _mastered = {};
  File? _file;
  bool _initialized = false;

  /// Must be called once at app startup before routing to home.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/path_progress.json');
      if (await _file!.exists()) {
        final contents = await _file!.readAsString();
        final decoded = jsonDecode(contents);

        if (decoded is List) {
          // Legacy format: plain list of visited IDs
          _visited.addAll(decoded.cast<String>());
        } else if (decoded is Map) {
          // Current format: {visited: [...], mastered: [...]}
          final v = (decoded['visited'] as List?)?.cast<String>() ?? [];
          final m = (decoded['mastered'] as List?)?.cast<String>() ?? [];
          _visited.addAll(v);
          _mastered.addAll(m);
        }
        debugPrint('[PathProgressService] loaded ${_visited.length} visited, '
            '${_mastered.length} mastered');
      }
    } catch (e) {
      debugPrint('[PathProgressService] init error: $e');
    }
    _initialized = true;
  }

  // ── Visited ──────────────────────────────────────────────────────────────

  void markVisited(String techniqueId) {
    if (_visited.add(techniqueId)) _persist();
  }

  bool isVisited(String techniqueId) => _visited.contains(techniqueId);

  int countVisited(List<String> techniqueIds) =>
      techniqueIds.where(_visited.contains).length;

  // ── Mastered (passed knowledge quiz) ─────────────────────────────────────

  void markMastered(String techniqueId) {
    _visited.add(techniqueId); // mastered implies visited
    if (_mastered.add(techniqueId)) _persist();
  }

  bool isMastered(String techniqueId) => _mastered.contains(techniqueId);

  int countMastered(List<String> techniqueIds) =>
      techniqueIds.where(_mastered.contains).length;

  // ── Persistence ───────────────────────────────────────────────────────────

  void _persist() {
    final data = jsonEncode({
      'visited': _visited.toList(),
      'mastered': _mastered.toList(),
    });
    _file?.writeAsString(data).catchError((Object e) {
      debugPrint('[PathProgressService] persist error: $e');
      return _file!;
    });
  }
}
