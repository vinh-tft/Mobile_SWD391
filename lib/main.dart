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
import 'services/api_client.dart';
import 'services/items_service.dart';
import 'services/health_service.dart';
import 'services/users_service.dart';
import 'services/points_service.dart';
import 'services/categories_service.dart';
import 'services/brands_service.dart';
import 'services/sales_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'services/fake_api_client.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // API client and services
        Provider<ApiClient>(create: (_) {
          // Use local backend in debug for easier testing
          const String defaultProd = 'https://greenloop.up.railway.app';
          // On Android emulator, localhost is 10.0.2.2
          const String androidLocal = 'http://10.0.2.2:8085';
          const String desktopLocal = 'http://localhost:8085';
          final String base = kIsWeb
              ? desktopLocal
              : (defaultTargetPlatform == TargetPlatform.android && kDebugMode ? androidLocal : (kDebugMode ? desktopLocal : defaultProd));
          return ApiClient(baseUrl: base);
        }),
        // Health uses fake to keep UI indicator green when mocking
        ChangeNotifierProvider<HealthService>(
          create: (context) {
            const bool useFakeData = true; // Mock everything except login
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return HealthService(api);
          },
        ),

        // Core state
        ChangeNotifierProvider(create: (context) => AuthService(context.read<ApiClient>())),
        ChangeNotifierProvider(create: (context) => ClothingService()),
        ChangeNotifierProvider<ItemsService>(
          create: (context) {
            const bool useFakeData = true;
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return ItemsService(api);
          },
        ),
        ChangeNotifierProvider<CategoriesService>(
          create: (context) {
            const bool useFakeData = true;
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return CategoriesService(api);
          },
        ),
        ChangeNotifierProvider<BrandsService>(
          create: (context) {
            const bool useFakeData = true;
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return BrandsService(api);
          },
        ),
        ChangeNotifierProvider<SalesService>(
          create: (context) {
            const bool useFakeData = true;
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return SalesService(api);
          },
        ),
        Provider<UsersService>(
          create: (context) {
            const bool useFakeData = true;
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return UsersService(api);
          },
        ),
        Provider<PointsService>(
          create: (context) {
            const bool useFakeData = true;
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            final auth = context.read<AuthService>();
            return PointsService(api, auth);
          },
        ),
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
  bool _hasInitializedRole = false;

  @override
  void initState() {
    super.initState();
    // Non-blocking health check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthService>().ping();
      // Initialize demo clothing data outside build to avoid setState during build
      final clothingService = context.read<ClothingService>();
      if (clothingService.clothingItems.isEmpty) {
        clothingService.initializeDemoData();
      }
      // Initialize role-based navigation
      _initializeRoleBasedNavigation();
    });
  }

  void _initializeRoleBasedNavigation() {
    final authService = context.read<AuthService>();
    if (authService.isLoggedIn && !_hasInitializedRole) {
      _hasInitializedRole = true;
      if (authService.isStaff) {
        // Staff users start at marketplace (inventory management)
        setState(() {
          _selectedIndex = 1;
        });
      } else {
        // Customer users start at home
        setState(() {
          _selectedIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, ClothingService>(
      builder: (context, authService, clothingService, child) {
        // Check for role-based navigation when auth state changes
        if (authService.isLoggedIn && !_hasInitializedRole) {
          print('🔍 Main - User logged in, role: ${authService.currentUser?.role}');
          print('🔍 Main - isStaff: ${authService.isStaff}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeRoleBasedNavigation();
          });
        }
        
        // Authentication Guard - Yêu cầu login trước khi vào app
        if (!authService.isLoggedIn) {
          return const LoginPage();
        }
        
        // User đã login, hiển thị app chính
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
    final backendUp = context.watch<HealthService>().backendUp;
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
          ),
          child: Row(
            children: authService.isStaff ? [
              Expanded(child: _buildBottomNavItem(Icons.home, 'Trang chủ', 0)),
              Expanded(child: _buildBottomNavItem(Icons.inventory, 'Quản lý', 1)),
              Expanded(child: _buildBottomNavItem(Icons.receipt_long, 'Giao dịch', 2)),
              Expanded(child: _buildBottomNavItem(Icons.person, 'Nhân viên', 3)),
            ] : [
              Expanded(child: _buildBottomNavItem(Icons.home, 'Trang chủ', 0)),
              Expanded(child: _buildBottomNavItem(Icons.shopping_bag, 'Cửa hàng', 1)),
              Expanded(child: _buildBottomNavItem(Icons.person, 'Cá nhân', 2)),
            ],
          ),
        ),
        Positioned(
          right: 10,
          top: 6,
          child: GestureDetector(
            onTap: () => context.read<HealthService>().ping(),
            child: Row(
              children: [
                // Points chip always visible when logged in
                if (authService.isLoggedIn) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, size: 10, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${authService.currentUser?.points ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
                // Role indicator
                if (authService.isLoggedIn) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: authService.isStaff ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      authService.isStaff ? 'STAFF' : 'USER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // API status
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: backendUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  backendUp ? 'API OK' : 'API lỗi',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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