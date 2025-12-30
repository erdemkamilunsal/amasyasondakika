import 'package:flutter/material.dart';

class VefatPage extends StatelessWidget {
  const VefatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vefat"),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text("Vefat ilanları burada olacak."),
      ),
    );
  }
}
