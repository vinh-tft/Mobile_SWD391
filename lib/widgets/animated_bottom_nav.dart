import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Modern Animated Bottom Navigation Bar
/// Sleek design with smooth animations
class AnimatedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color backgroundColor;
  final Color indicatorColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final Duration animationDuration;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = const Color(0xFF10B981), // Green primary
    this.indicatorColor = const Color(0xFF34D399), // Light green
    this.selectedIconColor = Colors.white,
    this.unselectedIconColor = const Color(0xFFFFFFFF),
    this.animationDuration = const Duration(milliseconds: 350),
  }) : assert(items.length >= 2 && items.length <= 5);

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Animated Indicator
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final itemWidth = MediaQuery.of(context).size.width / widget.items.length;
                final startPos = _previousIndex * itemWidth + itemWidth / 2;
                final endPos = widget.currentIndex * itemWidth + itemWidth / 2;
                final currentPos = startPos + (endPos - startPos) * _animation.value;

                return Positioned(
                  top: -4,
                  left: currentPos - 25,
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.indicatorColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.indicatorColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Navigation Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                widget.items.length,
                (index) => _buildNavItem(
                  widget.items[index],
                  index,
                  widget.currentIndex,
                  widget.onTap,
                  widget.selectedIconColor,
                  widget.unselectedIconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BottomNavItem item,
    int index,
    int currentIndex,
    Function(int) onTap,
    Color selectedIconColor,
    Color unselectedIconColor,
  ) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon with Scale
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      item.icon,
                      size: 24,
                      color: isSelected ? selectedIconColor : unselectedIconColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // Animated Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? selectedIconColor : unselectedIconColor,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  final Widget? badge;

  const BottomNavItem({
    required this.icon,
    required this.label,
    this.badge,
  });
}
