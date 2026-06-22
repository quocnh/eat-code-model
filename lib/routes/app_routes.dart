import 'package:flutter/material.dart';
import '../screens/company_cards.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static const String home = '/main';
  static const String bookmarks = '/bookmarks';
  static const String progress = '/progress';
  static const String settings = '/settings';
  static const String companies = '/companies';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const MainNavigationScreen(),
        bookmarks: (context) => const BookmarksScreen(),
        progress: (context) => const ProgressScreen(),
        settings: (context) => const SettingsScreen(),
        companies: (context) => const CompanyCards(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle unknown routes here
    return MaterialPageRoute(
      builder: (context) => const MainNavigationScreen(),
    );
  }
}
