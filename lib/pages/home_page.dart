import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/clothing_service.dart';
import 'marketplace_page.dart';
import 'profile_page.dart';
import 'recharge_page.dart';
import 'staff_recharge_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, ClothingService>(
      builder: (context, authService, clothingService, child) {
        return SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(authService),
                  
                  // Hero Section
                  _buildHeroSection(authService),
                  
                  // Quick Actions
                  _buildQuickActions(authService),
                  
                  // Statistics Section
                  _buildStatistics(),
                  
                  // Feature Cards Section
                  _buildFeatureCards(authService),
                  
                  // Why Choose Section
                  _buildWhyChooseSection(),
                  
                  // Bottom Feature Cards
                  _buildBottomFeatureCards(),
                  
                  // Newsletter Section
                  _buildNewsletterSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthService authService) {
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
          // User info
          Row(
            children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Color(0xFF22C55E),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${authService.currentUser?.points ?? 0} điểm',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(width: 8),
              const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF6B7280),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(AuthService authService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Text(
            authService.isStaff ? 'Quản lý cửa hàng' : 'Cửa hàng quần áo xanh',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            authService.isStaff 
                ? 'Nạp điểm cho khách hàng, quản lý kho hàng và xem giao dịch'
                : 'Nạp điểm, mua quần áo bằng điểm, hoặc đem quần áo cũ đến cửa hàng để đổi lấy điểm',
            style: const TextStyle(
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
                child: _buildButton(
                  authService.isStaff ? 'Nạp điểm cho KH' : 'Nạp điểm', 
                  true, 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => authService.isStaff 
                            ? const StaffRechargePage()
                            : const RechargePage(),
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildButton(
                  authService.isStaff ? 'Quản lý kho' : 'Mua quần áo', 
                  false, 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketplacePage()),
                    );
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, bool isPrimary, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

  Widget _buildFeatureCards(AuthService authService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
              'Cách thức hoạt động',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildFeatureCard('Nạp điểm', 'Nạp điểm vào tài khoản', Icons.account_balance_wallet)),
                const SizedBox(width: 16),
                Expanded(child: _buildFeatureCard('Mua sắm', 'Dùng điểm mua quần áo', Icons.shopping_bag)),
                const SizedBox(width: 16),
                Expanded(child: _buildFeatureCard('Đổi quần áo', 'Đem quần áo cũ đến cửa hàng', Icons.swap_horiz)),
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

  Widget _buildQuickActions(AuthService authService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chức năng chính',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: authService.isStaff ? [
              Expanded(
                child: _buildQuickActionCard(
                  'Nạp điểm cho KH',
                  Icons.account_balance_wallet,
                  const Color(0xFF22C55E),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StaffRechargePage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Quản lý kho',
                  Icons.inventory,
                  const Color(0xFF3B82F6),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketplacePage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Xem giao dịch',
                  Icons.receipt_long,
                  const Color(0xFF8B5CF6),
                  () {
                    // Navigation sẽ được xử lý bởi bottom navigation
                  },
                ),
              ),
            ] : [
              Expanded(
                child: _buildQuickActionCard(
                  'Nạp điểm',
                  Icons.account_balance_wallet,
                  const Color(0xFF22C55E),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RechargePage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Mua quần áo',
                  Icons.shopping_bag,
                  const Color(0xFF3B82F6),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketplacePage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Đổi quần áo',
                  Icons.swap_horiz,
                  const Color(0xFF8B5CF6),
                  () {
                    _showExchangeDialog(context, authService);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsletterSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22C55E).withOpacity(0.1),
            const Color(0xFF16A34A).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.email,
            color: Color(0xFF22C55E),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Stay Updated',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get the latest updates on sustainable fashion and exclusive offers',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Enter your email',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscribed successfully!'),
                      backgroundColor: Color(0xFF22C55E),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Subscribe'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showExchangeDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi quần áo lấy điểm'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store,
              size: 64,
              color: Color(0xFF22C55E),
            ),
            SizedBox(height: 16),
            Text(
              'Đem quần áo cũ đến cửa hàng để đổi lấy điểm',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Địa chỉ: 123 Đường ABC, Quận 1, TP.HCM',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Giờ mở cửa: 8:00 - 20:00',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã ghi nhận! Hãy đến cửa hàng để đổi quần áo'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
