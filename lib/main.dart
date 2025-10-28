import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/marketplace_page.dart';
import 'pages/loved_page.dart';
import 'pages/profile_page.dart';
import 'pages/posts_page.dart';
import 'pages/transactions_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/clothing_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => ClothingService()),
      ],
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
    return Consumer2<AuthService, ClothingService>(
      builder: (context, authService, clothingService, child) {
        // Nếu chưa đăng nhập, hiển thị trang đăng nhập
        if (!authService.isLoggedIn) {
          return const LoginPage();
        }

        // Khởi tạo dữ liệu demo khi đăng nhập lần đầu
        if (clothingService.clothingItems.isEmpty) {
          clothingService.initializeDemoData();
        }

        // Nếu đã đăng nhập, hiển thị trang chính
        return Scaffold(
          backgroundColor: Colors.white,
                body: SafeArea(
                  child: _getCurrentPage(authService),
                ),
                bottomNavigationBar: _buildBottomNavigation(authService),
        );
      },
    );
  }

  Widget _getCurrentPage(AuthService authService) {
    if (authService.isStaff) {
      switch (_selectedIndex) {
        case 0:
          return const HomePage();
        case 1:
          return const MarketplacePage();
        case 2:
          return const TransactionsPage();
        case 3:
          return const ProfilePage();
        default:
          return const HomePage();
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return const HomePage();
        case 1:
          return const MarketplacePage();
        case 2:
          return const ProfilePage();
        default:
          return const HomePage();
      }
    }
  }

  Widget _buildBottomNavigation(AuthService authService) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF22C55E),
      ),
      child: Row(
        children: authService.isStaff ? [
          Expanded(child: _buildBottomNavItem(Icons.home, 'Trang chủ', 0)),
          Expanded(child: _buildBottomNavItem(Icons.inventory, 'Kho hàng', 1)),
          Expanded(child: _buildBottomNavItem(Icons.receipt_long, 'Giao dịch', 2)),
          Expanded(child: _buildBottomNavItem(Icons.person, 'Cá nhân', 3)),
        ] : [
          Expanded(child: _buildBottomNavItem(Icons.home, 'Trang chủ', 0)),
          Expanded(child: _buildBottomNavItem(Icons.shopping_bag, 'Cửa hàng', 1)),
          Expanded(child: _buildBottomNavItem(Icons.person, 'Cá nhân', 2)),
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