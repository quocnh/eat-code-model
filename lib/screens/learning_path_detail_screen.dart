import 'package:flutter/material.dart';
import '../models/learning_path.dart';
import '../data/training_data.dart';
import '../data/quiz_data.dart';
import '../services/path_progress_service.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import 'technique_detail_screen.dart';
import 'interview_simulation_screen.dart';
import 'knowledge_test_screen.dart';

class LearningPathDetailScreen extends StatefulWidget {
  final LearningPath path;

  const LearningPathDetailScreen({super.key, required this.path});

  @override
  State<LearningPathDetailScreen> createState() =>
      _LearningPathDetailScreenState();
}

class _LearningPathDetailScreenState extends State<LearningPathDetailScreen> {
  final _progress = PathProgressService();

  void _onNodeTap(PathNode node) {
    if (node.type == PathNodeType.interviewChallenge) {
      final lastTechNode = widget.path.nodes.lastWhere(
        (n) => n.type == PathNodeType.technique,
        orElse: () => widget.path.nodes.first,
      );
      final technique = lastTechNode.techniqueId != null
          ? TrainingData.getById(lastTechNode.techniqueId!)
          : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InterviewSimulationScreen(
            technique: technique,
            pathName: widget.path.name,
            pathColor: widget.path.color,
          ),
        ),
      );
      return;
    }

    if (node.techniqueId == null) return;
    final technique = TrainingData.getById(node.techniqueId!);
    if (technique == null) return;

    _progress.markVisited(node.techniqueId!);
    setState(() {});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TechniqueDetailScreen(technique: technique),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _openQuiz(PathNode node) async {
    if (node.techniqueId == null) return;
    final technique = TrainingData.getById(node.techniqueId!);
    final passed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeTestScreen(
          techniqueId: node.techniqueId!,
          techniqueName: node.displayName,
          pathColor: widget.path.color,
        ),
      ),
    );
    if (passed == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pathColor = widget.path.color;
    final techniqueIds = widget.path.nodes
        .where((n) => n.techniqueId != null)
        .map((n) => n.techniqueId!)
        .toList();
    final visited = _progress.countVisited(techniqueIds);
    final mastered = _progress.countMastered(techniqueIds);
    final total = widget.path.techniqueCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: pathColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(widget.path.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.path.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeader(pathColor, visited, mastered, total),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: _buildNodeList(pathColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color pathColor, int visited, int mastered, int total) {
    return Container(
      color: pathColor,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.path.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Visited count
              _headerStat('📖', '$visited', 'studied'),
              const SizedBox(width: 16),
              // Mastered count
              _headerStat('⭐', '$mastered', 'mastered'),
              const SizedBox(width: 12),
              // Progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$mastered / $total',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? mastered / total : 0,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String emoji, String count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNodeList(Color pathColor) {
    final items = <Widget>[];
    for (int i = 0; i < widget.path.nodes.length; i++) {
      final node = widget.path.nodes[i];
      final isLast = i == widget.path.nodes.length - 1;
      items.add(_buildNodeCard(node, i, pathColor));
      if (!isLast) items.add(_buildConnector(pathColor));
    }
    return items;
  }

  Widget _buildConnector(Color pathColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 2, height: 14, color: pathColor.withOpacity(0.3)),
          Icon(Icons.arrow_downward, color: pathColor.withOpacity(0.6), size: 18),
          Container(width: 2, height: 14, color: pathColor.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildNodeCard(PathNode node, int index, Color pathColor) {
    if (node.type == PathNodeType.interviewChallenge) {
      return _buildInterviewChallengeCard(pathColor);
    }

    final technique =
        node.techniqueId != null ? TrainingData.getById(node.techniqueId!) : null;
    final visited =
        node.techniqueId != null ? _progress.isVisited(node.techniqueId!) : false;
    final mastered =
        node.techniqueId != null ? _progress.isMastered(node.techniqueId!) : false;
    final hasQuiz = node.techniqueId != null &&
        QuizData.forTechnique(node.techniqueId!).isNotEmpty;

    // State: unvisited → visited → mastered
    final Color statusColor = mastered
        ? const Color(0xFFF59E0B)   // gold for mastered
        : visited
            ? pathColor             // path colour for visited
            : pathColor.withOpacity(0.12); // dim for unvisited

    return GestureDetector(
      onTap: () => _onNodeTap(node),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: mastered
                ? const Color(0xFFF59E0B).withOpacity(0.5)
                : visited
                    ? pathColor.withOpacity(0.4)
                    : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status circle
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: mastered
                        ? const Text('⭐', style: TextStyle(fontSize: 14))
                        : visited
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: pathColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                  ),
                  const SizedBox(width: 14),
                  // Emoji badge
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pathColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(node.icon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  // Name + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.displayName,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (technique != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            technique.shortDescription,
                            style: AppTextStyles.body2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (technique != null) _difficultyBadge(technique.difficulty),
                      const SizedBox(height: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Quiz button (shown when visited but quiz exists) ────────────
            if (visited && hasQuiz) ...[
              const Divider(height: 1),
              InkWell(
                onTap: () => _openQuiz(node),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        mastered ? Icons.emoji_events : Icons.quiz_outlined,
                        size: 16,
                        color: mastered
                            ? const Color(0xFFF59E0B)
                            : pathColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mastered ? '⭐ Quiz Passed — Retake?' : 'Take Knowledge Quiz',
                        style: TextStyle(
                          color: mastered ? const Color(0xFFF59E0B) : pathColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: mastered
                            ? const Color(0xFFF59E0B)
                            : pathColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewChallengeCard(Color pathColor) {
    return GestureDetector(
      onTap: () => _onNodeTap(
        widget.path.nodes
            .firstWhere((n) => n.type == PathNodeType.interviewChallenge),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [pathColor.withOpacity(0.85), pathColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: pathColor.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interview Challenge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simulate a real technical interview — hints, complexity, optimization & more.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _difficultyBadge(String difficulty) {
    Color color;
    switch (difficulty) {
      case 'Beginner':
        color = AppColors.success;
        break;
      case 'Intermediate':
        color = AppColors.warning;
        break;
      case 'Advanced':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
