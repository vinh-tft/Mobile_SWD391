import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../constants/colors.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: isMobile ? 40 : 80,
      ),
      child: Column(
        children: [
          Text(
            'Why Choose Green Loop?',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms).slideY(),
          const SizedBox(height: 16),
          Text(
            'We\'re revolutionizing fashion with innovative features that make sustainable shopping easy and rewarding.',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.gray,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(),
          const SizedBox(height: 64),
          
          // Feature cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: isMobile ? 1.5 : 1.2,
            children: [
              _buildFeatureCard(
                icon: FontAwesomeIcons.recycle,
                title: 'Circular Economy',
                description: 'Extend the lifecycle of clothing through buying, selling, and renting pre-loved items.',
              ).animate().fadeIn(duration: 800.ms, delay: 400.ms).slideY(),
              _buildFeatureCard(
                icon: FontAwesomeIcons.leaf,
                title: 'Sustainability Tracking',
                description: 'Monitor your environmental impact with detailed sustainability metrics and user log.',
              ).animate().fadeIn(duration: 800.ms, delay: 600.ms).slideY(),
              _buildFeatureCard(
                icon: FontAwesomeIcons.shield,
                title: 'Quality Assurance',
                description: 'Every item is verified for quality and authenticity before listing on our platform.',
              ).animate().fadeIn(duration: 800.ms, delay: 800.ms).slideY(),
              _buildFeatureCard(
                icon: FontAwesomeIcons.users,
                title: 'Community Driven',
                description: 'Connect with like-minded individuals who share your passion for sustainable fashion.',
              ).animate().fadeIn(duration: 800.ms, delay: 1000.ms).slideY(),
              _buildFeatureCard(
                icon: FontAwesomeIcons.brain,
                title: 'Smart Matching',
                description: 'AI-powered recommendations help you discover items that match your style and values.',
              ).animate().fadeIn(duration: 800.ms, delay: 1200.ms).slideY(),
              _buildFeatureCard(
                icon: FontAwesomeIcons.star,
                title: 'Reward System',
                description: 'Earn sustainability points and rewards for your eco-friendly fashion choices.',
              ).animate().fadeIn(duration: 800.ms, delay: 1400.ms).slideY(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
