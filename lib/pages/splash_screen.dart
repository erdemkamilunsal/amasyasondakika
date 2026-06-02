import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextPage;

  const SplashScreen({
    super.key,
    required this.nextPage,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> frames = const [
    'assets/loading/ferhat_frame_1.png',
    'assets/loading/ferhat_frame_2.png',
    'assets/loading/ferhat_frame_3.png',
    'assets/loading/ferhat_frame_4.png',
  ];

  int currentFrame = 0;
  Timer? frameTimer;
  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();

    frameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        currentFrame = (currentFrame + 1) % frames.length;
      });
    });

    navigationTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => widget.nextPage,
        ),
      );
    });
  }

  @override
  void dispose() {
    frameTimer?.cancel();
    navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Image.asset(
                frames[currentFrame],
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Amasya yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}