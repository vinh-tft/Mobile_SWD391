import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../constants/colors.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: isMobile ? 40 : 60,
      ),
      decoration: const BoxDecoration(
        color: AppColors.dark,
      ),
      child: Column(
        children: [
          // Footer content
          isMobile ? _buildMobileFooter() : _buildDesktopFooter(),
          
          const SizedBox(height: 40),
          
          // Copyright
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.gray.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            '© 2024 Green Loop. All rights reserved.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray,
            ),
          ).animate().fadeIn(duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildDesktopFooter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: Green Loop
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.leaf,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ).animate().scale(duration: 600.ms),
                  const SizedBox(width: 12),
                  const Text(
                    'Green Loop',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Making fashion circular, one item at a time.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray,
                  height: 1.5,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
            ],
          ),
        ),
        
        // Column 2: Platform
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
              const SizedBox(height: 16),
              _buildFooterLink('Marketplace'),
              _buildFooterLink('Join'),
              _buildFooterLink('How it Works'),
            ],
          ),
        ),
        
        // Column 3: Company
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Company',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 600.ms),
              const SizedBox(height: 16),
              _buildFooterLink('About'),
              _buildFooterLink('Contact'),
              _buildFooterLink('Careers'),
            ],
          ),
        ),
        
        // Column 4: Support
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 800.ms),
              const SizedBox(height: 16),
              _buildFooterLink('Help Center'),
              _buildFooterLink('Privacy'),
              _buildFooterLink('Terms'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo section
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.leaf,
                color: AppColors.white,
                size: 16,
              ),
            ).animate().scale(duration: 600.ms),
            const SizedBox(width: 12),
            const Text(
              'Green Loop',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ).animate().fadeIn(duration: 800.ms).slideX(),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Making fashion circular, one item at a time.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray,
            height: 1.5,
          ),
        ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
        
        const SizedBox(height: 32),
        
        // Links in grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3,
          children: [
            _buildFooterLink('Marketplace'),
            _buildFooterLink('Join'),
            _buildFooterLink('About'),
            _buildFooterLink('Contact'),
            _buildFooterLink('Help Center'),
            _buildFooterLink('Privacy'),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gray,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}
