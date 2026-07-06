import 'package:flutter/material.dart';
import '../models/learning_path.dart';

class LearningPathData {
  static final List<LearningPath> paths = [
    // -----------------------------------------------------------------------
    // Path 1: Array Patterns
    // Hash Map → Two Pointers → Sliding Window → Monotonic Stack
    // -----------------------------------------------------------------------
    LearningPath(
      id: 'array-patterns',
      name: 'Array Patterns',
      description:
          'Master core array techniques — from O(1) lookup all the way to window-based optimization.',
      emoji: '📋',
      color: const Color(0xFF1565C0),
      difficulty: 'Beginner → Intermediate',
      nodes: const [
        PathNode(
          id: 'ap-1',
          type: PathNodeType.technique,
          techniqueId: 'hashmap',
          displayName: 'Hash Map / Set',
          icon: '#️⃣',
        ),
        PathNode(
          id: 'ap-2',
          type: PathNodeType.technique,
          techniqueId: 'two-pointers',
          displayName: 'Two Pointers',
          icon: '👆',
        ),
        PathNode(
          id: 'ap-3',
          type: PathNodeType.technique,
          techniqueId: 'sliding-window',
          displayName: 'Sliding Window',
          icon: '🪟',
        ),
        PathNode(
          id: 'ap-4',
          type: PathNodeType.technique,
          techniqueId: 'monotonic-stack',
          displayName: 'Monotonic Stack',
          icon: '📊',
        ),
        PathNode(
          id: 'ap-ic',
          type: PathNodeType.interviewChallenge,
          displayName: 'Interview Challenge',
          icon: '🎯',
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // Path 2: Search & Dynamic Programming
    // Binary Search → Greedy → DP 1D → DP 2D
    // -----------------------------------------------------------------------
    LearningPath(
      id: 'search-dp',
      name: 'Search & DP',
      description:
          'From divide-and-conquer search to full dynamic programming mastery.',
      emoji: '🔍',
      color: const Color(0xFF2E7D32),
      difficulty: 'Beginner → Advanced',
      nodes: const [
        PathNode(
          id: 'sd-1',
          type: PathNodeType.technique,
          techniqueId: 'binary-search',
          displayName: 'Binary Search',
          icon: '🔍',
        ),
        PathNode(
          id: 'sd-2',
          type: PathNodeType.technique,
          techniqueId: 'greedy',
          displayName: 'Greedy',
          icon: '💰',
        ),
        PathNode(
          id: 'sd-3',
          type: PathNodeType.technique,
          techniqueId: 'dp-1d',
          displayName: 'Dynamic Programming 1D',
          icon: '📊',
        ),
        PathNode(
          id: 'sd-4',
          type: PathNodeType.technique,
          techniqueId: 'dp-2d',
          displayName: 'Dynamic Programming 2D',
          icon: '📐',
        ),
        PathNode(
          id: 'sd-ic',
          type: PathNodeType.interviewChallenge,
          displayName: 'Interview Challenge',
          icon: '🎯',
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // Path 3: Graphs & Trees
    // Stack → BFS/Trees → DFS/Backtracking → Union-Find
    // -----------------------------------------------------------------------
    LearningPath(
      id: 'graphs-trees',
      name: 'Graphs & Trees',
      description:
          'Traversal algorithms and graph connectivity — from stack basics to Union-Find.',
      emoji: '🌳',
      color: const Color(0xFF6A1B9A),
      difficulty: 'Intermediate',
      nodes: const [
        PathNode(
          id: 'gt-1',
          type: PathNodeType.technique,
          techniqueId: 'stack',
          displayName: 'Stack',
          icon: '📚',
        ),
        PathNode(
          id: 'gt-2',
          type: PathNodeType.technique,
          techniqueId: 'bfs-trees',
          displayName: 'BFS / Tree Traversal',
          icon: '🌳',
        ),
        PathNode(
          id: 'gt-3',
          type: PathNodeType.technique,
          techniqueId: 'dfs-backtracking',
          displayName: 'DFS / Backtracking',
          icon: '🔀',
        ),
        PathNode(
          id: 'gt-4',
          type: PathNodeType.technique,
          techniqueId: 'union-find',
          displayName: 'Union-Find',
          icon: '🔗',
        ),
        PathNode(
          id: 'gt-ic',
          type: PathNodeType.interviewChallenge,
          displayName: 'Interview Challenge',
          icon: '🎯',
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // Path 4: Advanced Data Structures
    // Linked List → Heap → Trie
    // -----------------------------------------------------------------------
    LearningPath(
      id: 'advanced-structures',
      name: 'Advanced Structures',
      description:
          'Node-based and priority-driven structures — Linked List, Heap, and Trie.',
      emoji: '🏗️',
      color: const Color(0xFFBF360C),
      difficulty: 'Intermediate → Advanced',
      nodes: const [
        PathNode(
          id: 'as-1',
          type: PathNodeType.technique,
          techniqueId: 'linked-list',
          displayName: 'Linked List',
          icon: '🔗',
        ),
        PathNode(
          id: 'as-2',
          type: PathNodeType.technique,
          techniqueId: 'heap',
          displayName: 'Heap / Priority Queue',
          icon: '⛰️',
        ),
        PathNode(
          id: 'as-3',
          type: PathNodeType.technique,
          techniqueId: 'trie',
          displayName: 'Trie (Prefix Tree)',
          icon: '🌳',
        ),
        PathNode(
          id: 'as-ic',
          type: PathNodeType.interviewChallenge,
          displayName: 'Interview Challenge',
          icon: '🎯',
        ),
      ],
    ),
  ];
}
