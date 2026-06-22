import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateToReplacement(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void goBack() {
    return navigatorKey.currentState!.pop();
  }

  static Future<Object?> navigateToHomeScreen() {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  static BuildContext? get currentContext => navigatorKey.currentState?.context;
}