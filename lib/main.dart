import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/marketplace_page.dart';
import 'pages/loved_page.dart';
import 'pages/profile_page.dart';
import 'pages/posts_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const GreenLoopApp(),
    ),
  );
}

class GreenLoopApp extends StatelessWidget {
  const GreenLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Loop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const GreenLoopHomePage(),
    );
  }
}

class GreenLoopHomePage extends StatefulWidget {
  const GreenLoopHomePage({super.key});

  @override
  State<GreenLoopHomePage> createState() => _GreenLoopHomePageState();
}

class _GreenLoopHomePageState extends State<GreenLoopHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Nếu chưa đăng nhập, hiển thị trang đăng nhập
        if (!authService.isLoggedIn) {
          return const LoginPage();
        }

        // Nếu đã đăng nhập, hiển thị trang chính
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: _getCurrentPage(),
          ),
          bottomNavigationBar: _buildBottomNavigation(),
        );
      },
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const MarketplacePage();
      case 2:
        return const PostsPage();
      case 3:
        return const LovedPage();
      case 4:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF22C55E),
      ),
      child: Row(
        children: [
          Expanded(child: _buildBottomNavItem(Icons.home, 'Home', 0)),
          Expanded(child: _buildBottomNavItem(Icons.shopping_bag, 'Market', 1)),
          Expanded(child: _buildBottomNavItem(Icons.article, 'Posts', 2)),
          Expanded(child: _buildBottomNavItem(Icons.favorite, 'Loved', 3)),
          Expanded(child: _buildBottomNavItem(Icons.person, 'Profile', 4)),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}