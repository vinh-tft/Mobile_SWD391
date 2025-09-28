import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleGreenLoopApp());
}

class SimpleGreenLoopApp extends StatelessWidget {
  const SimpleGreenLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Loop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SimpleHomePage(),
    );
  }
}

class SimpleHomePage extends StatelessWidget {
  const SimpleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Green Loop'),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recycling,
              size: 64,
              color: Color(0xFF22C55E),
            ),
            SizedBox(height: 16),
            Text(
              'Green Loop',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sustainable Fashion Platform',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
