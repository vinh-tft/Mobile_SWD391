import 'package:flutter/material.dart';

class LovedPage extends StatefulWidget {
  const LovedPage({super.key});

  @override
  State<LovedPage> createState() => _LovedPageState();
}

class _LovedPageState extends State<LovedPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          _buildHeader(),
          
          // Loved Items Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: const Text(
              'Loved Items',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          
          // Empty State
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const Icon(
                  Icons.favorite_border,
                  color: Color(0xFF6B7280),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No loved items yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start exploring and add items you love to your collection',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to marketplace - this would need to be handled by parent
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigate to Marketplace'),
                        backgroundColor: Color(0xFF22C55E),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Explore Marketplace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.recycling,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Green Loop',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle
          const Icon(
            Icons.wb_sunny_outlined,
            color: Color(0xFF6B7280),
            size: 24,
          ),
        ],
      ),
    );
  }
}
