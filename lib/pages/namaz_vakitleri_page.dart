import 'package:flutter/material.dart';

class NamazVakitleriPage extends StatelessWidget {
  const NamazVakitleriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Vakitleri'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text(
          'Namaz vakitleri sayfası (placeholder). Gerçek içerik eklenecek.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
