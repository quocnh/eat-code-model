import 'package:flutter/material.dart';
import '../widgets/custom_nav_bar.dart';
import 'company_cards.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'training_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final _homeKey = GlobalKey<HomeScreenState>();
  final progressKey = GlobalKey<ProgressScreenState>();

  late final List<Widget> _screens;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      HomeScreen(key: _homeKey),
      const CompanyCards(),
      const TrainingScreen(),
      ProgressScreen(key: progressKey),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _refreshCurrentScreen(int newIndex) {
    // Always update the current index first
    setState(() {
      _currentIndex = newIndex;
    });

    // Animate to the new page
    _pageController.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Refresh the appropriate screen based on the new index
    switch (newIndex) {
      case 0:
        _homeKey.currentState?.refreshCards();
        break;
      case 3:
        progressKey.currentState?.refreshProgress();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to change pages
        children: _screens,
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _refreshCurrentScreen,
      ),
    );
  }
}
