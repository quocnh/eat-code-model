/// In-memory service that tracks which technique IDs the user has visited
/// during the current app session. No persistence across restarts — intentional
/// for now so there is zero extra dependency.
class PathProgressService {
  static final PathProgressService _instance = PathProgressService._();
  factory PathProgressService() => _instance;
  PathProgressService._();

  final Set<String> _visited = {};

  void markVisited(String techniqueId) => _visited.add(techniqueId);

  bool isVisited(String techniqueId) => _visited.contains(techniqueId);

  /// Returns how many IDs from [techniqueIds] have been visited.
  int countVisited(List<String> techniqueIds) =>
      techniqueIds.where(_visited.contains).length;
}
