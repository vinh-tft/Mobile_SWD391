import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/app_provider.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final appProvider = Provider.of<AppProvider>(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: isMobile ? 40 : 80,
      ),
      child: isMobile 
        ? _buildMobileLayout(context, appProvider)
        : _buildDesktopLayout(context, appProvider, isTablet),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Circular Fashion for a',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 800.ms).slideX(),
        Text(
          'Greener Future',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideX(),
        
        const SizedBox(height: 24),
        
        // Description
        Text(
          'Join the sustainable fashion revolution. Buy, sell, and rent pre-loved clothing while reducing waste and building a circular economy.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.gray,
            height: 1.6,
          ),
        ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
        
        const SizedBox(height: 32),
        
        // CTA Button
        ElevatedButton(
          onPressed: () => appProvider.navigateToMarketplace(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Explore Marketplace',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().scale(duration: 600.ms, delay: 600.ms),
        
        const SizedBox(height: 40),
        
        // Feature Cards
        ..._buildFeatureCards().map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: card,
        )),
        
        const SizedBox(height: 40),
        
        // Statistics
        _buildMobileStats(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppProvider appProvider, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Text content
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Circular Fashion for a',
                style: TextStyle(
                  fontSize: isTablet ? 36 : 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 800.ms).slideX(),
              Text(
                'Greener Future',
                style: TextStyle(
                  fontSize: isTablet ? 36 : 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideX(),
              const SizedBox(height: 24),
              Text(
                'Join the sustainable fashion revolution. Buy, sell, and rent pre-loved clothing while reducing waste and building a circular economy.',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 18,
                  color: AppColors.gray,
                  height: 1.6,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => appProvider.navigateToMarketplace(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Explore Marketplace',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().scale(duration: 600.ms, delay: 600.ms),
              const SizedBox(height: 48),
              // Statistics
              _buildDesktopStats(),
            ],
          ),
        ),
        
        SizedBox(width: isTablet ? 40 : 80),
        
        // Right side - Feature cards
        Expanded(
          flex: 1,
          child: Column(
            children: _buildFeatureCards(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureCards() {
    return [
      _buildFeatureCard(
        icon: FontAwesomeIcons.bagShopping,
        title: 'Marketplace',
      ).animate().fadeIn(duration: 800.ms, delay: 800.ms).slideY(),
      const SizedBox(height: 24),
      _buildFeatureCard(
        icon: FontAwesomeIcons.heart,
        title: 'Loved Items',
      ).animate().fadeIn(duration: 800.ms, delay: 1000.ms).slideY(),
      const SizedBox(height: 24),
      _buildFeatureCard(
        icon: FontAwesomeIcons.chartLine,
        title: 'Impact Score',
      ).animate().fadeIn(duration: 800.ms, delay: 1200.ms).slideY(),
    ];
  }

  Widget _buildDesktopStats() {
    return Row(
      children: [
        _buildStat('10K+', 'Users').animate().fadeIn(duration: 800.ms, delay: 800.ms),
        const SizedBox(width: 48),
        _buildStat('5K+', 'Happy Users').animate().fadeIn(duration: 800.ms, delay: 1000.ms),
        const SizedBox(width: 48),
        _buildStat('95%', 'Satisfaction').animate().fadeIn(duration: 800.ms, delay: 1200.ms),
      ],
    );
  }

  Widget _buildMobileStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat('10K+', 'Users').animate().fadeIn(duration: 800.ms, delay: 800.ms),
        _buildStat('5K+', 'Happy Users').animate().fadeIn(duration: 800.ms, delay: 1000.ms),
        _buildStat('95%', 'Satisfaction').animate().fadeIn(duration: 800.ms, delay: 1200.ms),
      ],
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
