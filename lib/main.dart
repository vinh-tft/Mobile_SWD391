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
import 'services/google_auth_service.dart';
import 'services/cart_service.dart';
import 'services/chat_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/animated_bottom_nav.dart';
import 'pages/cart_page.dart';
import 'pages/chat_list_page.dart';
import 'pages/chat_page_redesigned.dart';
import 'pages/video_call_page.dart';
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
          const String androidLocal = 'http://10.0.2.2:8080';
          const String desktopLocal = 'http://localhost:8080';
          final String base = kIsWeb
              ? desktopLocal
              : (defaultTargetPlatform == TargetPlatform.android && kDebugMode ? androidLocal : (kDebugMode ? desktopLocal : defaultProd));
          return ApiClient(baseUrl: base);
        }),
        // Health uses real API now
        ChangeNotifierProvider<HealthService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return HealthService(api);
          },
        ),

        // Google Auth Service
        Provider<GoogleAuthService>(
          create: (context) => GoogleAuthService(context.read<ApiClient>()),
        ),
        
        // Cart Service (no API needed)
        ChangeNotifierProvider(create: (_) => CartService()),
        
        // Core state - all using real API
        ChangeNotifierProvider(create: (context) => AuthService(context.read<ApiClient>())),
        ChangeNotifierProvider(create: (context) => ClothingService()),
        ChangeNotifierProvider<ItemsService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return ItemsService(api);
          },
        ),
        ChangeNotifierProvider<CategoriesService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return CategoriesService(api);
          },
        ),
        ChangeNotifierProvider<BrandsService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return BrandsService(api);
          },
        ),
        ChangeNotifierProvider<SalesService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return SalesService(api);
          },
        ),
        Provider<UsersService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return UsersService(api);
          },
        ),
        Provider<PointsService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            final auth = context.read<AuthService>();
            return PointsService(api, auth);
          },
        ),
        Provider<ChatService>(
          create: (context) {
            const bool useFakeData = false; // Use real API
            final api = useFakeData ? FakeApiClient() : context.read<ApiClient>();
            return ChatService(api);
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Can be changed to ThemeMode.system for auto dark mode
      home: const GreenLoopHomePage(),
      // Add named routes for easy navigation
      routes: {
        '/cart': (context) => const CartPage(),
        '/chat': (context) => const ChatListPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/video-call') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => VideoCallPage(
              name: args?['name'] ?? 'Unknown',
              userId: args?['id'],
            ),
          );
        }
        return null;
      },
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
          bottomNavigationBar: _buildAnimatedBottomNavigation(authService),
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
      // Customer navigation
      switch (_selectedIndex) {
        case 0:
          return const HomePage();
        case 1:
          return const MarketplacePage();
        case 2:
          return const CartPage();
        case 3:
          return const ChatListPage();
        case 4:
          return const ProfilePage();
        default:
          return const HomePage();
      }
    }
  }

  Widget _buildAnimatedBottomNavigation(AuthService authService) {
    final backendUp = context.watch<HealthService>().backendUp;
    final cart = context.watch<CartService>();
    
    // Define navigation items based on role
    final List<BottomNavItem> items = authService.isStaff 
      ? [
          const BottomNavItem(icon: Icons.home_rounded, label: 'Trang chủ'),
          const BottomNavItem(icon: Icons.inventory_2_rounded, label: 'Quản lý'),
          const BottomNavItem(icon: Icons.receipt_long_rounded, label: 'Giao dịch'),
          const BottomNavItem(icon: Icons.person_rounded, label: 'Nhân viên'),
        ]
      : [
          const BottomNavItem(icon: Icons.home_rounded, label: 'Trang chủ'),
          const BottomNavItem(icon: Icons.shopping_bag_rounded, label: 'Cửa hàng'),
          const BottomNavItem(icon: Icons.shopping_cart_rounded, label: 'Giỏ hàng'),
          const BottomNavItem(icon: Icons.chat_rounded, label: 'Tin nhắn'),
          const BottomNavItem(icon: Icons.person_rounded, label: 'Cá nhân'),
        ];

    return Stack(
      children: [
        // Main animated navigation bar - Using theme colors
        AnimatedBottomNav(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: items,
          backgroundColor: AppColors.primary, // Green Loop primary color
          indicatorColor: AppColors.primaryLight, // Light green indicator
          selectedIconColor: Colors.white,
          unselectedIconColor: AppColors.whiteWithOpacity(0.6),
          animationDuration: const Duration(milliseconds: 300),
        ),
        // Cart Badge (for customers only)
        if (!authService.isStaff && cart.itemCount > 0)
          Positioned(
            top: 8,
            left: MediaQuery.of(context).size.width * 0.4 + 20, // Position over cart icon (adjusted for 5 tabs)
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.destructive,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        // Status indicators overlay - Using theme colors
        Positioned(
          right: 10,
          top: 8,
          child: GestureDetector(
            onTap: () => context.read<HealthService>().ping(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.whiteWithOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Points chip
                  if (authService.isLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.whiteWithOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars, size: 10, color: AppColors.primaryLight),
                          const SizedBox(width: 3),
                          Text(
                            '${authService.currentUser?.points ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // API status dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: backendUp ? AppColors.statusOnline : AppColors.destructive,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (backendUp ? AppColors.statusOnline : AppColors.destructive)
                              .withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}