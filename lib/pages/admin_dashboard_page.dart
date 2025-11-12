import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin_items_page.dart';
import 'admin_donations_page.dart';
import 'admin_brands_page.dart';
import 'admin_categories_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulated API call for dashboard stats
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for demonstration
    setState(() {
      _stats = {
        'totalUsers': 2543,
        'userChange': '+12%',
        'activeListings': 1234,
        'listingsChange': '+8%',
        'itemsSold': 856,
        'salesChange': '+23%',
        'revenue': 2231,
        'revenueChange': '+15%',
        'recentActivities': [
          {
            'user': 'Sarah Johnson',
            'action': 'listed a new item',
            'item': 'Vintage Denim Jacket',
            'time': '2 minutes ago',
          },
          {
            'user': 'Mike Chen',
            'action': 'purchased',
            'item': 'Sustainable T-Shirt',
            'time': '15 minutes ago',
          },
          {
            'user': 'Emma Davis',
            'action': 'added to cart',
            'item': 'Recycled Cotton Dress',
            'time': '30 minutes ago',
          },
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Switch to User View button
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Go back to user view
            },
            icon: const Icon(Icons.person_outline, color: Colors.white, size: 20),
            label: const Text(
              'User View',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    _buildStatsGrid(),

                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(),

                    const SizedBox(height: 24),

                    // Recent Activities
                    _buildRecentActivities(),

                    const SizedBox(height: 24),

                    // Revenue Chart Placeholder
                    _buildRevenueChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    if (_stats == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Users',
          _stats!['totalUsers'].toString(),
          _stats!['userChange'],
          Icons.people,
          const Color(0xFF3B82F6),
        ),
        _buildStatCard(
          'Active Listings',
          _stats!['activeListings'].toString(),
          _stats!['listingsChange'],
          Icons.shopping_bag,
          const Color(0xFF8B5CF6),
        ),
        _buildStatCard(
          'Sold',
          _stats!['itemsSold'].toString(),
          _stats!['salesChange'],
          Icons.inventory,
          const Color(0xFFF59E0B),
        ),
        _buildStatCard(
          'Revenue',
          '\$${_stats!['revenue']}',
          _stats!['revenueChange'],
          Icons.attach_money,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    final isPositive = change.startsWith('+');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'from last month',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            // Staff features (Admin và Staff đều có)
            _buildQuickActionCard(
              'Manage\nProducts',
              Icons.inventory_outlined,
              const Color(0xFF8B5CF6),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminItemsPage(),
                  ),
                );
              },
            ),
            _buildQuickActionCard(
              'Manage\nDonations',
              Icons.inventory_2_outlined,
              const Color(0xFFEC4899),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDonationsPage(),
                  ),
                );
              },
            ),
            // Admin only features
            if (Provider.of<AuthService>(context, listen: false).isAdmin) ...[
              _buildQuickActionCard(
                'Manage\nBrands',
                Icons.branding_watermark_outlined,
                const Color(0xFF10B981),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminBrandsPage(),
                    ),
                  );
                },
              ),
              _buildQuickActionCard(
                'Manage\nCategories',
                Icons.category_outlined,
                const Color(0xFFF59E0B),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCategoriesPage(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    if (_stats == null || _stats!['recentActivities'] == null) {
      return const SizedBox.shrink();
    }

    final activities = _stats!['recentActivities'] as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Color(0xFF6B7280), size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.map((activity) => _buildActivityItem(
                activity['user'],
                activity['action'],
                activity['item'],
                activity['time'],
              )),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String user,
    String action,
    String? item,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF22C55E),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    children: [
                      TextSpan(
                        text: user,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' $action '),
                      if (item != null)
                        TextSpan(
                          text: item,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF6B7280), size: 20),
              SizedBox(width: 8),
              Text(
                'Revenue Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Revenue for the last 6 months',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chart will be implemented here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

