import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pages/district_selection_page.dart';
import '../../pages/navigation/main_navigation_page.dart';
import '../../pages/splash_screen.dart';

class AppStartController extends StatefulWidget {
  const AppStartController({super.key});

  @override
  State<AppStartController> createState() => _AppStartControllerState();
}

class _AppStartControllerState extends State<AppStartController> {
  bool? hasSeen;

  @override
  void initState() {
    super.initState();
    checkStartup();
  }

  Future<void> checkStartup() async {
    await Future.delayed(const Duration(milliseconds: 600)); // smooth açılış
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool("hasSeenDistrictSelection") ?? false;

    setState(() {
      hasSeen = seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (hasSeen == null) {
      return const SplashScreen();
    }

    return hasSeen!
        ? const MainNavigationPage()
        : const DistrictSelectionPage();
  }
}
