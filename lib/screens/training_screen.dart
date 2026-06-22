import 'package:flutter/material.dart';
import '../models/technique.dart';
import '../data/training_data.dart';
import '../styles/colors.dart';
import '../styles/text_styles.dart';
import 'technique_detail_screen.dart';
import 'ai_problem_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => TrainingScreenState();
}

class TrainingScreenState extends State<TrainingScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fundamental',
    'Tree/Graph',
    'Advanced',
    'Optimization',
  ];

  List<Technique> get _filteredTechniques {
    if (_selectedCategory == 'All') return TrainingData.techniques;
    return TrainingData.getByCategory(_selectedCategory);
  }

  Map<String, List<Technique>> get _groupedTechniques {
    final Map<String, List<Technique>> grouped = {};
    for (final technique in _filteredTechniques) {
      grouped.putIfAbsent(technique.category, () => []).add(technique);
    }
    return grouped;
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return AppColors.success;
      case 'Intermediate':
        return AppColors.warning;
      case 'Advanced':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

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
                MaterialPageRoute(
                  builder: (_) => const AiProblemScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAiBanner(context),
          _buildCategoryFilter(),
          Expanded(child: _buildTechniqueList()),
        ],
      ),
    );
  }

  Widget _buildAiBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiProblemScreen()),
        );
      },
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
              child:
                  const Icon(Icons.psychology, color: Colors.white, size: 28),
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

  Widget _buildCategoryFilter() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = category);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechniqueList() {
    final grouped = _groupedTechniques;
    if (grouped.isEmpty) {
      return const Center(
        child: Text(
          'No techniques found.',
          style: AppTextStyles.body2,
        ),
      );
    }

    final categoryOrder = [
      'Fundamental',
      'Tree/Graph',
      'Advanced',
      'Optimization',
    ];

    final orderedKeys = categoryOrder
        .where((cat) => grouped.containsKey(cat))
        .toList()
      ..addAll(grouped.keys.where((k) => !categoryOrder.contains(k)));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _selectedCategory == 'All' ? orderedKeys.length : 1,
      itemBuilder: (context, index) {
        final category =
            _selectedCategory == 'All' ? orderedKeys[index] : _selectedCategory;
        final techniques = grouped[category] ?? [];
        return _buildCategorySection(category, techniques);
      },
    );
  }

  Widget _buildCategorySection(String category, List<Technique> techniques) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedCategory == 'All')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              category,
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ...techniques.map((t) => _buildTechniqueCard(t)),
      ],
    );
  }

  Widget _buildTechniqueCard(Technique technique) {
    final diffColor = _difficultyColor(technique.difficulty);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechniqueDetailScreen(technique: technique),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                technique.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          technique.name,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          technique.difficulty,
                          style: TextStyle(
                            color: diffColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    technique.shortDescription,
                    style: AppTextStyles.body2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          technique.timeComplexity,
                          style: AppTextStyles.body2.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.memory_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          technique.spaceComplexity,
                          style: AppTextStyles.body2.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
