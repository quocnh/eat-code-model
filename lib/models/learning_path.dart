import 'package:flutter/material.dart';

enum PathNodeType { technique, interviewChallenge }

class PathNode {
  final String id;
  final PathNodeType type;
  final String? techniqueId;
  final String displayName;
  final String icon;

  const PathNode({
    required this.id,
    required this.type,
    this.techniqueId,
    required this.displayName,
    required this.icon,
  });
}

class LearningPath {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final List<PathNode> nodes;
  final String difficulty;

  const LearningPath({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.nodes,
    required this.difficulty,
  });

  int get techniqueCount =>
      nodes.where((n) => n.type == PathNodeType.technique).length;
}
