import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/brands_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';
import 'admin_brand_create_page.dart';
import 'admin_brand_edit_page.dart';

class AdminBrandsPage extends StatefulWidget {
  const AdminBrandsPage({super.key});

  @override
  State<AdminBrandsPage> createState() => _AdminBrandsPageState();
}

class _AdminBrandsPageState extends State<AdminBrandsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 0;
  Map<String, int> _stats = {'totalBrands': 0, 'verifiedBrands': 0, 'partnerBrands': 0};
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadBrands();
    _loadStats();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isEmpty) {
        _loadBrands();
      } else {
        _searchBrands();
      }
    });
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    try {
      final brandsService = context.read<BrandsService>();
      final result = await brandsService.loadBrandsPaginated(page: _currentPage, size: 20);
      setState(() {
        _totalPages = result['totalPages'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _searchBrands() async {
    if (_searchController.text.trim().isEmpty) {
      _loadBrands();
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    try {
      final brandsService = context.read<BrandsService>();
      final result = await brandsService.searchBrandsPaginated(
        _searchController.text.trim(),
        page: _currentPage,
        size: 20,
      );
      setState(() {
        _totalPages = result['totalPages'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final brandsService = context.read<BrandsService>();
      final stats = await brandsService.getStatistics();
      setState(() => _stats = stats);
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _currentPage = page;
    });

    try {
      final brandsService = context.read<BrandsService>();
      final result = _searchController.text.trim().isEmpty
          ? await brandsService.loadBrandsPaginated(page: page, size: 20)
          : await brandsService.searchBrandsPaginated(
              _searchController.text.trim(),
              page: page,
              size: 20,
            );
      setState(() {
        _totalPages = result['totalPages'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading page: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(BrandResponse brand, bool isActive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Archive Brand?' : 'Restore Brand?'),
        content: Text(
          isActive
              ? 'The brand will be hidden but can be restored later.'
              : 'The brand will be displayed again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isActive ? 'Archive' : 'Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final brandsService = context.read<BrandsService>();
      final success = isActive
          ? await brandsService.deleteBrand(brand.brandId)
          : await brandsService.restoreBrand(brand.brandId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Brand archived' : 'Brand restored'),
          ),
        );
        _loadBrands();
        _loadStats();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${brandsService.error ?? 'Unable to perform action'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Check if user has admin access
    if (user == null || !authService.hasAdminAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text('Only admin and staff can access this page'),
        ),
      );
    }

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
          'Manage Brands',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        // Removed add button - brands are read-only for admin/staff
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBrands();
          await _loadStats();
        },
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search brands...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        _stats['totalBrands'] ?? 0,
                        Icons.business,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Verified',
                        _stats['verifiedBrands'] ?? 0,
                        Icons.verified,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Partners',
                        _stats['partnerBrands'] ?? 0,
                        Icons.handshake,
                        AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Brands Grid
            Consumer<BrandsService>(
              builder: (context, brandsService, _) {
                if (_isLoading && brandsService.brands.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final brands = brandsService.brands;

                if (brands.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.trim().isEmpty
                                ? 'No brands yet'
                                : 'No brands found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildBrandCard(brands[index]),
                      childCount: brands.length,
                    ),
                  ),
                );
              },
            ),

            // Pagination
            if (_totalPages > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () => _loadPage(_currentPage - 1)
                            : null,
                      ),
                      Text(
                        'Page ${_currentPage + 1} / $_totalPages',
                        style: const TextStyle(fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _loadPage(_currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value.toString(),
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
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(BrandResponse brand) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminBrandEditPage(brand: brand),
            ),
          );
          if (result == true) {
            _loadBrands();
            _loadStats();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Name
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              brand.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.business, size: 24),
                            ),
                          )
                        : Icon(Icons.business, size: 24, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '/${brand.slug}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Badges
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (brand.isVerified == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppColors.success),
                          const SizedBox(width: 2),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (brand.isPartner == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.handshake, size: 12, color: AppColors.info),
                          const SizedBox(width: 2),
                          Text(
                            'Partner',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Description
              if (brand.description != null && brand.description!.isNotEmpty)
                Text(
                  brand.description!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 8),

              // Read-only: No actions available
            ],
          ),
        ),
      ),
    );
  }
}
