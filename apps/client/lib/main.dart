import 'package:flutter/material.dart';

void main() {
  runApp(const BennuApp());
}

class BennuApp extends StatelessWidget {
  const BennuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bennu',
      theme: ThemeData(useMaterial3: true),
      home: const BennuHomePage(),
    );
  }
}

class BennuHomePage extends StatelessWidget {
  const BennuHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bennu Command Center')),
      body: const Center(
        child: Text('Bennu client ready. Authentication is handled by the API.'),
      ),
    );
  }
}
