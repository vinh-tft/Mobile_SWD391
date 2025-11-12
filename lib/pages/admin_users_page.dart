import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/users_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 0;
  Timer? _searchDebounce;
  
  Map<String, int> _stats = {
    'totalUsers': 0,
    'activeUsers': 0,
    'verifiedUsers': 0,
    'bannedUsers': 0,
  };

  Map<String, int> _usersByRole = {};
  List<Map<String, dynamic>> _users = [];

  late UsersService _usersService;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _usersService = UsersService(apiClient);
    _loadStats();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final response = await _usersService.getUserManagementSummary(page: 0, size: 20);
      
      if (response is Map && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            _stats = {
              'totalUsers': (data['totalUsers'] ?? 0) as int,
              'activeUsers': (data['activeUsers'] ?? 0) as int,
              'verifiedUsers': (data['verifiedUsers'] ?? 0) as int,
              'bannedUsers': (data['bannedUsers'] ?? 0) as int,
            };
            
            if (data['usersByRole'] is Map) {
              _usersByRole = Map<String, int>.from(
                (data['usersByRole'] as Map).map(
                  (key, value) => MapEntry(key.toString(), (value as num).toInt()),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      Map<String, dynamic> result;
      
      if (_searchController.text.isNotEmpty) {
        result = await _usersService.searchUsersPaginated(
          _searchController.text,
          page: _currentPage,
          size: 20,
        );
      } else {
        result = await _usersService.getAllUsersPaginated(
          page: _currentPage,
          size: 20,
        );
      }
      
      if (mounted) {
        setState(() {
          if (result is Map && result['data'] is Map) {
            final data = result['data'] as Map<String, dynamic>;
            
            if (data['content'] is List) {
              _users = (data['content'] as List)
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
            }
            
            _totalPages = (data['totalPages'] ?? 0) as int;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSearchChange(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentPage = 0;
      });
      _loadUsers();
    });
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
          'User',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStats();
          await _loadUsers();
        },
        color: AppColors.primary,
        child: Column(
          children: [
            // Stats Cards
            _buildStatsCards(),
            
            // Users by Role
            if (_usersByRole.isNotEmpty) _buildUsersByRole(),
            
            // Search Bar
            _buildSearchBar(),
            
            // Users List
            Expanded(
              child: _buildUsersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              _stats['totalUsers']!.toString(),
              Icons.people,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active',
              _stats['activeUsers']!.toString(),
              Icons.check_circle,
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Verified',
              _stats['verifiedUsers']!.toString(),
              Icons.verified,
              AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Banned',
              _stats['bannedUsers']!.toString(),
              Icons.block,
              AppColors.destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersByRole() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          const Text(
            'Users by Role',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _usersByRole.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _handleSearchChange,
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search, color: AppColors.mutedForeground),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length + (_totalPages > 1 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _users.length) {
          return _buildPagination();
        }
        
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username'] ?? '';
    final email = user['email'] ?? '';
    final fullName = user['fullName'] ?? user['firstName'] ?? user['lastName'] ?? username;
    final role = user['role'] ?? 'USER';
    final isActive = user['isActive'] ?? false;
    final isBanned = user['isBanned'] ?? false;
    final isVerified = user['isVerified'] ?? false;
    final sustainabilityPoints = user['sustainabilityPoints'] ?? 0;
    final sustainabilityScore = user['sustainabilityScore'] ?? 0.0;
    final followersCount = user['followersCount'] ?? 0;
    final listingsCount = user['listingsCount'] ?? 0;
    final createdAt = user['createdAt'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // User Info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.info],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
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
          
          const SizedBox(height: 12),
          
          // Role and Status Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  role,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
              if (isBanned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Banned',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.destructive,
                    ),
                  ),
                ),
              if (!isActive && !isBanned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Points and Stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sustainabilityPoints.toString()} points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'Eco: ${sustainabilityScore.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$followersCount followers',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    Text(
                      '$listingsCount listings',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Joined: ${_formatDate(createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} / $_totalPages',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _currentPage > 0
                    ? () {
                        setState(() => _currentPage--);
                        _loadUsers();
                      }
                    : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _currentPage < _totalPages - 1
                    ? () {
                        setState(() => _currentPage++);
                        _loadUsers();
                      }
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

