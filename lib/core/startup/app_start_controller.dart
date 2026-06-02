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
  bool? hasSeenDistrictSelection;

  @override
  void initState() {
    super.initState();
    _checkStartup();
  }

  Future<void> _checkStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenDistrictSelection') ?? false;

    if (!mounted) return;

    setState(() {
      hasSeenDistrictSelection = seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (hasSeenDistrictSelection == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (hasSeenDistrictSelection!) {
      return const SplashScreen(
        nextPage: MainNavigationPage(),
      );
    }

    return const SplashScreen(
      nextPage: DistrictSelectionPage(),
    );
  }
}