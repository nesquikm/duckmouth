import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duckmouth'),
      ),
      body: const Center(
        child: Text('Ready to record'),
      ),
    );
  }
}
