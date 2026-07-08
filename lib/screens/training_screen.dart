import 'package:flutter/material.dart';
import '../data/learning_path_data.dart';
import '../models/learning_path.dart';
import '../services/path_progress_service.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import 'ai_problem_screen.dart';
import 'learning_path_detail_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => TrainingScreenState();
}

class TrainingScreenState extends State<TrainingScreen> {
  final _progress = PathProgressService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Training',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology, color: Colors.white),
            tooltip: 'AI Problem Generator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiProblemScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildAiBanner(context),
          _buildInterviewTipsSection(),
          _buildSectionHeader(),
          ...LearningPathData.paths.map((path) => _buildPathCard(path)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Banner (unchanged from before — keeps AI feature visible)
  // ---------------------------------------------------------------------------

  Widget _buildAiBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiProblemScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Problem Generator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate custom coding problems on-device using AI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interview tips
  // ---------------------------------------------------------------------------

  static const List<Map<String, dynamic>> _tips = [
    {
      'icon': '🗣️',
      'title': 'Think Out Loud',
      'body': 'Narrate your reasoning as you go. Interviewers want to follow your thought process — silence is a red flag.',
      'color': Color(0xFF1565C0),
    },
    {
      'icon': '❓',
      'title': 'Clarify First',
      'body': 'Before coding, ask about edge cases, input ranges, and expected output format. 2 minutes of questions saves 20 minutes of rework.',
      'color': Color(0xFF00897B),
    },
    {
      'icon': '🐌',
      'title': 'Brute Force First',
      'body': 'Always state the naive O(n²) approach before optimising. It shows you can solve it and gives you a baseline to improve.',
      'color': Color(0xFF6A1B9A),
    },
    {
      'icon': '📐',
      'title': 'Big-O Analysis',
      'body': 'Volunteer time AND space complexity without being asked. Walk through the loop count and any extra data structures you allocate.',
      'color': Color(0xFF2E7D32),
    },
    {
      'icon': '🔲',
      'title': 'Dry Run',
      'body': 'Trace through your solution with a small example on the whiteboard before declaring it done. Catch off-by-one errors early.',
      'color': Color(0xFFBF360C),
    },
    {
      'icon': '⚠️',
      'title': 'Edge Cases',
      'body': 'Always test: empty input, single element, duplicates, negatives, and maximum bounds. Mention each one even if you do not code a test.',
      'color': Color(0xFFAD1457),
    },
    {
      'icon': '📝',
      'title': 'Write Clean Code',
      'body': 'Use meaningful variable names, avoid magic numbers, and add brief comments on non-obvious steps. Readability counts in interviews.',
      'color': Color(0xFF0277BD),
    },
    {
      'icon': '🤝',
      'title': 'Collaborate',
      'body': 'If stuck, say "I am thinking about X approach, does that align with what you have in mind?" Interviews are conversations, not solo exams.',
      'color': Color(0xFF558B2F),
    },
    {
      'icon': '⏱️',
      'title': 'Manage Time',
      'body': 'Spend ~5 min clarifying, ~5 min brute force, ~15 min optimising, ~5 min testing. Check the clock at each phase.',
      'color': Color(0xFFE65100),
    },
    {
      'icon': '🔄',
      'title': 'Pattern Recognition',
      'body': 'Most problems map to a handful of patterns: sliding window, two pointers, BFS/DFS, DP, or binary search. Ask yourself which one fits.',
      'color': Color(0xFF1976D2),
    },
  ];

  Widget _buildInterviewTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Interview Tips',
                style: AppTextStyles.heading2.copyWith(fontSize: 17),
              ),
              const SizedBox(width: 8),
              Text(
                '· tap to expand',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            itemCount: _tips.length,
            itemBuilder: (context, i) => _buildTipCard(context, _tips[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(BuildContext context, Map<String, dynamic> tip) {
    final color = tip['color'] as Color;
    return GestureDetector(
      onTap: () => _showTipDialog(context, tip),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tip['icon'] as String,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip['title'] as String,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.open_in_full, size: 13, color: color.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                tip['body'] as String,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.45,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to read more →',
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTipDialog(BuildContext context, Map<String, dynamic> tip) {
    final color = tip['color'] as Color;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(tip['icon'] as String,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip['title'] as String,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                tip['body'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: color),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section header
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Paths',
            style: AppTextStyles.heading2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Follow each path in order. Unlock the Interview Challenge when you\'re ready.',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Path card
  // ---------------------------------------------------------------------------

  Widget _buildPathCard(LearningPath path) {
    final techniqueIds = path.nodes
        .where((n) => n.techniqueId != null)
        .map((n) => n.techniqueId!)
        .toList();
    final visited = _progress.countVisited(techniqueIds);
    final mastered = _progress.countMastered(techniqueIds);
    final total = path.techniqueCount;
    final progressFraction = total > 0 ? mastered / total : 0.0;
    final isStarted = visited > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearningPathDetailScreen(path: path),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored header strip
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: path.color.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Emoji badge
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: path.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      path.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.name,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: path.color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          path.difficulty,
                          style: TextStyle(
                            color: path.color.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: path.color.withOpacity(0.6),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(path.description, style: AppTextStyles.body2),
                  const SizedBox(height: 12),

                  // Topic chain preview
                  _buildTopicChainPreview(path),

                  const SizedBox(height: 14),

                  // Progress row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isStarted
                                      ? '$mastered/$total mastered · $visited studied'
                                      : '${path.techniqueCount} topics + Interview',
                                  style: AppTextStyles.body2.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (isStarted)
                                  Text(
                                    '${(progressFraction * 100).round()}%',
                                    style: TextStyle(
                                      color: path.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressFraction,
                                backgroundColor: path.color.withOpacity(0.1),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(path.color),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: path.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isStarted ? 'Continue' : 'Start',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a compact horizontal preview of the topic nodes in the path.
  Widget _buildTopicChainPreview(LearningPath path) {
    final allNodes = path.nodes;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < allNodes.length; i++) ...[
            _buildMiniNode(allNodes[i], path.color),
            if (i < allNodes.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: path.color.withOpacity(0.4),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniNode(PathNode node, Color color) {
    final isInterview = node.type == PathNodeType.interviewChallenge;
    final visited = node.techniqueId != null
        ? _progress.isVisited(node.techniqueId!)
        : false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInterview
            ? color
            : visited
                ? color.withOpacity(0.15)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInterview
              ? color
              : visited
                  ? color.withOpacity(0.4)
                  : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(node.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            _shortName(node.displayName),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isInterview
                  ? Colors.white
                  : visited
                      ? color
                      : AppColors.textSecondary,
            ),
          ),
          if (visited && !isInterview) ...[
            const SizedBox(width: 3),
            Icon(Icons.check_circle, size: 10, color: color),
          ],
        ],
      ),
    );
  }

  String _shortName(String name) {
    const overrides = {
      'Dynamic Programming 1D': 'DP 1D',
      'Dynamic Programming 2D': 'DP 2D',
      'BFS / Tree Traversal': 'BFS',
      'DFS / Backtracking': 'DFS',
      'Heap / Priority Queue': 'Heap',
      'Trie (Prefix Tree)': 'Trie',
      'Interview Challenge': 'Interview',
      'Hash Map / Set': 'Hash Map',
      'Monotonic Stack': 'Mono Stack',
    };
    return overrides[name] ?? name;
  }
}
