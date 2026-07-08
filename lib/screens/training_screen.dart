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
