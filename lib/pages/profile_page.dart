import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/users_service.dart';
import '../services/orders_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import 'admin_dashboard_page.dart';
import 'profile_points_page.dart';
import 'profile_addresses_page.dart';
import 'profile_donations_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _fullUserData;
  
  // Edit form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  late UsersService _usersService;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _usersService = UsersService(apiClient);
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.id;
    
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userData = await _usersService.getUserById(userId);
      if (userData != null && mounted) {
        setState(() {
          _fullUserData = userData;
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _bioController.text = userData['bio'] ?? '';
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      // Fallback to auth user
      final authUser = authService.currentUser;
      if (authUser != null && mounted) {
        setState(() {
          _fullUserData = {
            'firstName': authUser.name.split(' ').first,
            'lastName': authUser.name.split(' ').length > 1 ? authUser.name.split(' ').last : '',
            'email': authUser.email,
            'username': authUser.email.split('@').first,
            'phone': '',
            'bio': '',
            'sustainabilityPoints': authUser.points,
            'ordersCount': 0,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.id;
    
    if (userId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
      };
      
      final updatedUser = await _usersService.updateUser(userId, updateData);
      if (updatedUser != null && mounted) {
        setState(() {
          _fullUserData = updatedUser;
          _isEditing = false;
        });
        
        // Reload user data
        await _loadUserData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelEdit() {
    if (_fullUserData != null) {
      setState(() {
        _firstNameController.text = _fullUserData!['firstName'] ?? '';
        _lastNameController.text = _fullUserData!['lastName'] ?? '';
        _phoneController.text = _fullUserData!['phone'] ?? '';
        _bioController.text = _fullUserData!['bio'] ?? '';
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final userPoints = user?.points ?? 0;
        
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Information Card
              _buildProfileInfoCard(authService),
              
              const SizedBox(height: 16),
              
              // Quick Stats Cards - Only for customers
              if (!authService.hasAdminAccess) ...[
                _buildQuickStatsCards(userPoints),
                const SizedBox(height: 16),
              ],
              
              // Menu Options
              _buildMenuOptions(authService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoCard(AuthService authService) {
    final firstName = _fullUserData?['firstName'] ?? '';
    final lastName = _fullUserData?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final username = _fullUserData?['username'] ?? authService.currentUser?.email?.split('@').first ?? '';
    final email = _fullUserData?['email'] ?? authService.currentUser?.email ?? '';
    final phone = _fullUserData?['phone'] ?? '';
    final bio = _fullUserData?['bio'] ?? '';
    final avatarUrl = _fullUserData?['avatarUrl'];
    final createdAt = _fullUserData?['createdAt'];
    
    return Container(
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
          // Header with Edit button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your personal information',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                if (!_isEditing)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.border),
                    ),
                  )
                else
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : _cancelEdit,
                        child: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mutedForeground,
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 16),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Profile Picture and Name
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    avatarUrl.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 40,
                                        color: AppColors.primary,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isNotEmpty ? fullName : username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Form Fields
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'First Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _firstNameController,
                                enabled: _isEditing,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: !_isEditing,
                                  fillColor: _isEditing ? null : AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _lastNameController,
                                enabled: _isEditing,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: !_isEditing,
                                  fillColor: _isEditing ? null : AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: TextEditingController(text: email),
                          enabled: false,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: !_isEditing,
                            fillColor: _isEditing ? null : AppColors.background,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bio',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bioController,
                          enabled: _isEditing,
                          maxLines: 4,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Tell us about yourself...',
                            filled: !_isEditing,
                            fillColor: _isEditing ? null : AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Contact Info Display
                if (!_isEditing && (email.isNotEmpty || phone.isNotEmpty || createdAt != null))
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        if (email.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email, size: 16, color: AppColors.mutedForeground),
                              const SizedBox(width: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        if (phone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, size: 16, color: AppColors.mutedForeground),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        if (createdAt != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: AppColors.mutedForeground),
                              const SizedBox(width: 4),
                              Text(
                                'Joined ${_formatDate(createdAt.toString())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards(int userPoints) {
    return _buildStatCard(
      'Available Points',
      userPoints.toString(),
      Icons.workspace_premium,
      AppColors.primary,
      () => _showPointsPage(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                side: BorderSide(color: AppColors.border),
              ),
              child: const Text(
                'View Points History',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions(AuthService authService) {
    return Column(
      children: [
        if (authService.hasAdminAccess)
          _buildProfileMenuItem(
            Icons.dashboard,
            'Staff Dashboard',
            () => _showAdminDashboard(),
            color: AppColors.info,
          ),
        if (authService.hasAdminAccess) ...[
          _buildProfileMenuItem(Icons.logout, 'Logout', () => _showLogoutDialog()),
        ] else ...[
          _buildProfileMenuItem(Icons.account_balance_wallet, 'My Points', () => _showPointsPage()),
          _buildProfileMenuItem(Icons.location_on, 'Addresses', () => _showAddressesPage()),
          _buildProfileMenuItem(Icons.inventory_2, 'My Donations', () => _showDonationsPage()),
          _buildProfileMenuItem(Icons.shopping_bag, 'My Orders', () => _showOrdersPage()),
          _buildProfileMenuItem(Icons.favorite, 'Loved Items', () {}),
          _buildProfileMenuItem(Icons.sell, 'My Listings', () => _showListingsPage()),
          _buildProfileMenuItem(Icons.settings, 'Settings', () => _showSettingsPage()),
          _buildProfileMenuItem(Icons.help, 'Help & Support', () => _showHelpPage()),
          _buildProfileMenuItem(Icons.logout, 'Logout', () => _showLogoutDialog()),
        ],
      ],
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final iconColor = color ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: AppColors.mutedForeground, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showAdminDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
    );
  }

  void _showPointsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePointsPage()),
    );
  }

  void _showAddressesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileAddressesPage()),
    );
  }

  void _showDonationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileDonationsPage()),
    );
  }

  void _showOrdersPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _OrdersPage()),
    );
  }

  void _showListingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _ListingsPage()),
    );
  }

  void _showSettingsPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettingsSheet(),
    );
  }

  void _showHelpPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _HelpPage()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final authService = Provider.of<AuthService>(context, listen: false);
              authService.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Logout successful'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Orders Page
class _OrdersPage extends StatefulWidget {
  const _OrdersPage();

  @override
  State<_OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<_OrdersPage> {
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 0;
  List<Map<String, dynamic>> _orders = [];
  
  late OrdersService _ordersService;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _ordersService = OrdersService(apiClient);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.id;
    
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _ordersService.getOrdersByBuyer(
        userId,
        page: _currentPage,
        size: 20,
      );
      
      if (mounted) {
        setState(() {
          if (response is Map && response['data'] is Map) {
            final data = response['data'] as Map<String, dynamic>;
            
            if (data['content'] is List) {
              _orders = (data['content'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            }
            
            _totalPages = (data['totalPages'] ?? 0) as int;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(Icons.shopping_bag, color: AppColors.primary, size: 32),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Orders',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'View purchase history and order details',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Orders List
                        ..._orders.map((order) => _buildOrderCard(order)),
                        
                        // Pagination
                        if (_totalPages > 1) _buildPagination(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start shopping for sustainable fashion!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to marketplace - you may need to adjust this based on your navigation
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Explore Marketplace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderCode = order['orderCode'] ?? order['orderId'] ?? '';
    final createdAt = order['createdAt'] ?? '';
    final totalItems = order['totalItems'] ?? 0;
    final status = order['status'] ?? '';
    final statusDisplayName = order['statusDisplayName'] ?? status;
    final totalAmount = order['totalAmount'] ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderCode',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Navigate to order detail page
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => OrderDetailPage(orderId: order['orderId']),
                  //   ),
                  // );
                },
                icon: Icon(Icons.visibility, color: AppColors.primary),
                tooltip: 'View details',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.inventory_2, size: 16, color: AppColors.mutedForeground),
              const SizedBox(width: 4),
              Text(
                '$totalItems products',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${totalAmount.toString()} points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final itemName = item['itemName'] ?? '';
                    final quantity = item['quantity'] ?? 0;
                    final subtotal = item['subtotal'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $itemName × $quantity - ${subtotal.toString()} points',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() => _currentPage--);
                    _loadOrders();
                  }
                : null,
            child: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Page ${_currentPage + 1} / $_totalPages',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: _currentPage < _totalPages - 1
                ? () {
                    setState(() => _currentPage++);
                    _loadOrders();
                  }
                : null,
            child: const Text('Next'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.destructive;
      case 'PENDING':
      case 'PROCESSING':
        return AppColors.warning;
      default:
        return AppColors.mutedForeground;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

class _ListingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add new listing'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildListingCard('Vintage Leather Jacket', '\$120', 'Active', 3),
          _buildListingCard('Designer Handbag', '\$85', 'Sold', 1),
          _buildListingCard('Vintage Sneakers', '\$65', 'Active', 2),
        ],
      ),
    );
  }

  Widget _buildListingCard(String title, String price, String status, int views) {
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image,
              color: Color(0xFF6B7280),
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
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: status == 'Active' ? const Color(0xFF22C55E).withOpacity(0.1) : const Color(0xFF6B7280).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: status == 'Active' ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$views views',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSettingsSection('Preferences', [
                    _buildSettingsItem(
                      'Notifications',
                      'Receive push notifications',
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    _buildSettingsItem(
                      'Dark Mode',
                      'Use dark theme',
                      Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    _buildSettingsItem(
                      'Language',
                      _selectedLanguage,
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                      onTap: () => _showLanguageDialog(),
                    ),
                  ]),
                  _buildSettingsSection('Account', [
                    _buildSettingsItem(
                      'Edit Profile',
                      'Update your personal information',
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                    ),
                    _buildSettingsItem(
                      'Change Password',
                      'Update your password',
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                    ),
                    _buildSettingsItem(
                      'Privacy Settings',
                      'Manage your privacy',
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                    ),
                  ]),
                  _buildSettingsSection('Support', [
                    _buildSettingsItem(
                      'Contact Us',
                      'Get in touch with our team',
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                    ),
                    _buildSettingsItem(
                      'Terms of Service',
                      'Read our terms and conditions',
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                    ),
                    _buildSettingsItem(
                      'Privacy Policy',
                      'Learn about our privacy practices',
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, String subtitle, Widget trailing, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German'].map((language) {
            return ListTile(
              title: Text(language),
              trailing: _selectedLanguage == language
                  ? const Icon(Icons.check, color: Color(0xFF22C55E))
                  : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = language;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHelpSection(context, 'Frequently Asked Questions', [
            'How do I sell an item?',
            'How do I contact a seller?',
            'What payment methods do you accept?',
            'How do I track my order?',
          ]),
          _buildHelpSection(context, 'Contact Support', [
            'Email: support@greenloop.com',
            'Phone: +1 (555) 123-4567',
            'Live Chat: Available 24/7',
          ]),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context, String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
              children: items.map((item) {
                return ListTile(
                  title: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected: $item'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
