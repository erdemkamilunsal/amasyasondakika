import 'package:flutter/material.dart';

class HavaDurumuPage extends StatelessWidget {
  const HavaDurumuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hava Durumu'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text(
          'Hava durumu sayfası (placeholder). API entegrasyonu eklenecek.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
