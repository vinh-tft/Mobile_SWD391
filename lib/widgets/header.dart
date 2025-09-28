import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/app_provider.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final appProvider = Provider.of<AppProvider>(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo with animation
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
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(width: 12),
              Text(
                'Green Loop',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ).animate().fadeIn(duration: 800.ms).slideX(),
            ],
          ),
          
          // Navigation Links (hidden on mobile)
          if (!isMobile)
            Row(
              children: [
                _buildNavItem('Features', () => appProvider.navigateToMarketplace()),
                const SizedBox(width: 32),
                _buildNavItem('About', () => appProvider.navigateToAbout()),
                const SizedBox(width: 32),
                _buildNavItem('Contact', () => appProvider.navigateToContact()),
              ],
            ).animate().fadeIn(duration: 1000.ms).slideY(),
          
          // Login Button
          ElevatedButton(
            onPressed: () => appProvider.navigateToLogin(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24, 
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Text(
              'Login',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().scale(duration: 600.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildNavItem(String text, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.dark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
