import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          _buildHeader(),
          
          // Hero Section
          _buildHeroSection(),
          
          // Statistics Section
          _buildStatistics(),
          
          // Feature Cards Section
          _buildFeatureCards(),
          
          // Why Choose Section
          _buildWhyChooseSection(),
          
          // Bottom Feature Cards
          _buildBottomFeatureCards(),
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

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const Text(
            'Circular Fashion for a Greener Future',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Join the sustainable fashion revolution. Buy, sell, and trade pre-loved clothing to reduce waste and create a circular economy.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildButton('Start Shopping', true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildButton('Learn More', false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, bool isPrimary) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF22C55E) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isPrimary ? null : Border.all(color: const Color(0xFF22C55E)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isPrimary ? Colors.white : const Color(0xFF22C55E),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Row(
        children: [
          Expanded(child: _buildStat('10K+', 'Items Saved')),
          Expanded(child: _buildStat('5K+', 'Happy Users')),
          Expanded(child: _buildStat('2K+', 'CO2 Reduced')),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF22C55E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildFeatureCard('Upload', 'List your items', Icons.upload)),
              const SizedBox(width: 16),
              Expanded(child: _buildFeatureCard('Browse', 'Find treasures', Icons.search)),
              const SizedBox(width: 16),
              Expanded(child: _buildFeatureCard('Trade', 'Swap & save', Icons.swap_horiz)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF22C55E),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Choose Green Loop?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          _buildWhyChooseItem('Eco-Friendly', 'Reduce fashion waste and carbon footprint'),
          _buildWhyChooseItem('Affordable', 'Get quality items at fraction of retail price'),
          _buildWhyChooseItem('Community', 'Join a community of conscious fashion lovers'),
        ],
      ),
    );
  }

  Widget _buildWhyChooseItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF22C55E),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFeatureCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          _buildBottomCard(
            'Sustainable Fashion Platform',
            'Join thousands of users making fashion more sustainable',
            Icons.eco,
          ),
          const SizedBox(height: 16),
          _buildBottomCard(
            'Circular Economy',
            'Extend the life of clothing through resale and trading',
            Icons.recycling,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF22C55E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
