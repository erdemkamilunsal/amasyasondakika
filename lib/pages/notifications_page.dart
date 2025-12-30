import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler"),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text("Henüz bir bildiriminiz yok."),
      ),
    );
  }
}
