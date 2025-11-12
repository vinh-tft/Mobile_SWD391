import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/items_service.dart';
import '../services/categories_service.dart';
import '../services/brands_service.dart';
import '../services/cart_service.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';
import '../utils/cloudinary_helper.dart';
import 'create_listing_page.dart';
import 'product_detail_page.dart';
import 'item_detail_page.dart';
import 'add_sale_item_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'cart_page.dart';
import 'admin_category_create_page.dart';
import 'admin_brand_create_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedBrandId;
  String _selectedSort = 'Newest';
  final List<String> _sortOptions = ['Newest', 'Price: Low to High', 'Price: High to Low', 'Popular'];
  
  // Filter states
  String? _selectedCondition;
  String? _selectedSize;
  bool? _verifiedOnly;
  int? _minPrice;
  int? _maxPrice;
  
  // View mode: 'grid' or 'list'
  String _viewMode = 'grid';
  
  // Liked items (local state, could be synced with backend)
  final Set<String> _likedItems = {};
  
  // Available sizes
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  
  // Price ranges (in points)
  final List<Map<String, dynamic>> _priceRanges = [
    {'label': 'Under 100k', 'min': null, 'max': 100000},
    {'label': '100k-300k', 'min': 100000, 'max': 300000},
    {'label': '300k-500k', 'min': 300000, 'max': 500000},
    {'label': 'Over 500k', 'min': 500000, 'max': null},
  ];
  String? _selectedPriceRange;
  
  bool _requestedLoad = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_requestedLoad) {
        _requestedLoad = true;
        _loadData();
      }
    });
  }

  // Reload items when filters change
  void _onFiltersChanged() {
    if (mounted) {
      _loadItemsWithFilters();
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadItemsWithFilters(),
      context.read<CategoriesService>().loadActiveCategories(),
      context.read<BrandsService>().loadActiveBrands(),
    ]);
  }

  Future<void> _loadItemsWithFilters() async {
    final itemsService = context.read<ItemsService>();
    
    try {
      print('🔄 Loading items from server...');
      print('   - Category: $_selectedCategoryId');
      print('   - Brand: $_selectedBrandId');
      
      // Try filterItems API with READY_FOR_SALE status first (match React FE)
      await itemsService.filterItems(
        statuses: ['READY_FOR_SALE'], // Match React FE: ItemStatus.READY_FOR_SALE
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        page: 0,
        size: 12,
      );
      
      print('📦 Filtered items count: ${itemsService.items.length}');
      
      // If no items found, try without status filter (load all items)
      if (itemsService.items.isEmpty) {
        print('⚠️ No items with READY_FOR_SALE status, trying without status filter...');
        await itemsService.filterItems(
          statuses: null, // Try without status filter
          categoryId: _selectedCategoryId,
          brandId: _selectedBrandId,
          page: 0,
          size: 12,
        );
        print('📦 Items without status filter: ${itemsService.items.length}');
      }
      
      // If still no items, try loadMarketplaceReady
      if (itemsService.items.isEmpty) {
        print('⚠️ No items found with filterItems, trying loadMarketplaceReady...');
        await itemsService.loadMarketplaceReady();
        print('📦 Marketplace ready items: ${itemsService.items.length}');
      }
      
      // If still no items, try loading all items
      if (itemsService.items.isEmpty) {
        print('⚠️ No items found, trying loadItems...');
        await itemsService.loadItems(page: 0, size: 12);
        print('📦 All items: ${itemsService.items.length}');
      }
      
      if (itemsService.items.isNotEmpty) {
        print('✅ Successfully loaded ${itemsService.items.length} items from server');
      } else {
        print('⚠️ No items found from any API endpoint');
      }
    } catch (e, stackTrace) {
      print('❌ Error in _loadItemsWithFilters: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Fallback to loadMarketplaceReady if filterItems fails
      try {
        print('🔄 Fallback: Trying loadMarketplaceReady...');
        await itemsService.loadMarketplaceReady();
        print('📦 Fallback items: ${itemsService.items.length}');
      } catch (e2) {
        print('❌ loadMarketplaceReady also failed: $e2');
        // Last resort: try loadItems
        try {
          print('🔄 Last resort: Trying loadItems...');
          await itemsService.loadItems(page: 0, size: 12);
          print('📦 Last resort items: ${itemsService.items.length}');
        } catch (e3) {
          print('❌ loadItems also failed: $e3');
        }
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _searchItems() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      await context.read<ItemsService>().searchItems(query);
    } else {
      await _loadItemsWithFilters();
    }
  }

  List<ItemSummaryResponse> _getFilteredItems(List<ItemSummaryResponse> items) {
    var filtered = items;

    // Filter by category (using category name)
    if (_selectedCategoryId != null) {
      try {
        final categoriesService = context.read<CategoriesService>();
        if (categoriesService.categories.isNotEmpty) {
          final selectedCategory = categoriesService.categories.firstWhere(
            (cat) => cat.categoryId == _selectedCategoryId,
            orElse: () => categoriesService.categories.first,
          );
          filtered = filtered.where((item) => item.categoryName == selectedCategory.name).toList();
        }
      } catch (e) {
        // If category not found, skip filter
      }
    }

    // Filter by brand (using brand name)
    if (_selectedBrandId != null) {
      try {
        final brandsService = context.read<BrandsService>();
        if (brandsService.brands.isNotEmpty) {
          final selectedBrand = brandsService.brands.firstWhere(
            (brand) => brand.brandId == _selectedBrandId,
            orElse: () => brandsService.brands.first,
          );
          filtered = filtered.where((item) => item.brandName == selectedBrand.name).toList();
        }
      } catch (e) {
        // If brand not found, skip filter
      }
    }

    // Filter by condition
    if (_selectedCondition != null) {
      filtered = filtered.where((item) => 
        _getConditionText(item) == _selectedCondition
      ).toList();
    }

    // Filter by verified status
    if (_verifiedOnly == true) {
      filtered = filtered.where((item) => item.status == ItemStatus.VERIFIED).toList();
    }

    // Filter by size
    if (_selectedSize != null) {
      filtered = filtered.where((item) => item.size == _selectedSize).toList();
    }

    // Filter by price range
    if (_selectedPriceRange != null) {
      final range = _priceRanges.firstWhere(
        (r) => r['label'] == _selectedPriceRange,
        orElse: () => {},
      );
      if (range.isNotEmpty) {
        if (range['min'] != null) {
          filtered = filtered.where((item) => item.pointValue >= range['min']).toList();
        }
        if (range['max'] != null) {
          filtered = filtered.where((item) => item.pointValue <= range['max']).toList();
        }
      }
    }
    
    // Legacy price filter support
    if (_minPrice != null) {
      filtered = filtered.where((item) => item.pointValue >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((item) => item.pointValue <= _maxPrice!).toList();
    }

    // Sort items
    switch (_selectedSort) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.pointValue.compareTo(b.pointValue));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.pointValue.compareTo(a.pointValue));
        break;
      case 'Newest':
        // Sort by createdAt string (ISO format can be compared as strings)
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Popular':
        // Sort by viewCount + likeCount
        filtered.sort((a, b) => 
          (b.viewCount + b.likeCount).compareTo(a.viewCount + a.likeCount)
        );
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primary,
            child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
            _buildHeader(authService),
          
          // Search Bar
                _buildSearchBar(),
                
                // Category Chips
                _buildCategoryChips(),
                
                // Sort, Filter and View Mode Bar
                _buildSortFilterBar(),
                
                // Items Grid/List
                _buildItemsView(),
                
                // Load More Button - Match React FE
                Consumer<ItemsService>(
                  builder: (context, itemsService, _) {
                    final filteredItems = _getFilteredItems(itemsService.items);
                    if (filteredItems.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implement load more functionality
                              print('Load more items');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.foreground,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Load More Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: authService.isStaff ? _buildStaffFAB(context) : null,
        );
      },
    );
  }

  Widget _buildStaffFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
                          context,
          MaterialPageRoute(builder: (_) => const CreateListingPage()),
        );
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Add Product', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildHeader(AuthService authService) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.card,
      elevation: 0,
      title: GestureDetector(
        onTap: () {
          // Navigate to home - Match React FE: Link href="/"
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.recycling, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Green Loop',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Navigation Links - Match React FE: Home, Marketplace
        if (authService.isLoggedIn) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Home',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          TextButton(
            onPressed: null, // Current page
            child: Text(
              'Marketplace',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        
        // User Points Badge - Match React FE: bg-primary/10 rounded-full
        if (authService.isLoggedIn)
          Consumer<CartService>(
            builder: (context, cartService, _) {
              return Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1), // bg-primary/10
                      borderRadius: BorderRadius.circular(20), // rounded-full
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${authService.currentUser?.points ?? 0}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Shopping Cart - Match React FE: ShoppingBag icon with badge
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_bag_outlined, color: AppColors.mutedForeground, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartPage()),
                          );
                        },
                      ),
                      if (cartService.itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              cartService.itemCount > 9 ? '9+' : '${cartService.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // Notifications - Match React FE: Bell icon
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: AppColors.mutedForeground, size: 20),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  
                  // User Menu - Match React FE: User dropdown
                  _buildUserMenu(authService),
                ],
              );
            },
          )
        else
          // Not logged in - Match React FE: Sign In / Sign Up buttons
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
      ],
    );
  }
  
  Widget _buildUserMenu(AuthService authService) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getUserInitials(authService),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              authService.currentUser?.name ?? 'User',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: AppColors.mutedForeground, size: 18),
          ],
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
            break;
          case 'orders':
            // TODO: Navigate to orders page
            break;
          case 'settings':
            // TODO: Navigate to settings page
            break;
          case 'admin':
            if (authService.isStaff) {
              // TODO: Navigate to admin page
            }
            break;
          case 'add_item':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingPage()));
            break;
          case 'add_category':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoryCreatePage()));
            break;
          case 'add_brand':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBrandCreatePage()));
            break;
          case 'add_sale':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleItemPage()));
            break;
          case 'logout':
            authService.logout();
            Navigator.of(context).popUntil((route) => route.isFirst);
            break;
        }
      },
      itemBuilder: (context) => [
        // User Info Header
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authService.currentUser?.name ?? 'User',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authService.currentUser?.email ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${authService.currentUser?.points ?? 0} points',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        
        // Menu Items - Match React FE
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: AppColors.mutedForeground),
              const SizedBox(width: 12),
              const Text('My Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'orders',
          child: Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.mutedForeground),
              const SizedBox(width: 12),
              const Text('My Orders'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 16, color: AppColors.mutedForeground),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
        
        // Admin Workplace - Match React FE
        if (authService.isStaff) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'admin',
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 16, color: Colors.purple),
                const SizedBox(width: 12),
                Text(
                  'Staff Workplace',
                  style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
        
        // Staff actions (old menu)
        if (authService.isStaff) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'add_item', child: Text('Add Product')),
          const PopupMenuItem(value: 'add_category', child: Text('Add Category')),
          const PopupMenuItem(value: 'add_brand', child: Text('Add Brand')),
          const PopupMenuItem(value: 'add_sale', child: Text('Add Sale')),
        ],
        
        const PopupMenuDivider(),
        
        // Logout - Match React FE: red text
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 16, color: AppColors.destructive),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(color: AppColors.destructive),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getUserInitials(AuthService authService) {
    final user = authService.currentUser;
    if (user == null) return '?';
    final nameParts = user.name.trim().split(RegExp(r'\s+'));
    if (nameParts.isEmpty) return '?';
    final first = nameParts[0][0].toUpperCase();
    final last = nameParts.length > 1 ? nameParts[nameParts.length - 1][0].toUpperCase() : '';
    return (first + last);
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.input,
          borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
          children: [
              Icon(Icons.search, color: AppColors.mutedForeground, size: 22),
              const SizedBox(width: 12),
            Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 15),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _searchItems(),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: AppColors.mutedForeground, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                    _searchItems();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              // Search button
              IconButton(
                icon: Icon(Icons.search, color: AppColors.primary, size: 20),
                onPressed: _searchItems,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
                          ],
                        ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Consumer<CategoriesService>(
        builder: (context, categoriesService, _) {
          if (categoriesService.loading) {
            return const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final categories = categoriesService.categories;
          
    return Container(
      height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
        itemBuilder: (context, index) {
                if (index == 0) {
                  // "All" chip
                  final isSelected = _selectedCategoryId == null;
          return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: isSelected,
                      onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                      _onFiltersChanged();
                    },
                      backgroundColor: AppColors.card,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.mutedForeground,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                  );
                }
                
                final category = categories[index - 1];
                final isSelected = _selectedCategoryId == category.categoryId;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? category.categoryId : null;
                      });
                      _onFiltersChanged();
                    },
                    backgroundColor: AppColors.card,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.mutedForeground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                  ),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortFilterBar() {
    return SliverToBoxAdapter(
      child: Consumer<ItemsService>(
        builder: (context, itemsService, _) {
          final filteredItems = _getFilteredItems(itemsService.items);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredItems.length} products',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    // View mode toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewModeButton(Icons.grid_view, 'grid'),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.border,
                          ),
                          _buildViewModeButton(Icons.view_list, 'list'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showSortBottomSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sort, color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _selectedSort,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showFilterBottomSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _hasActiveFilters() ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: _hasActiveFilters() ? AppColors.primary : AppColors.border
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: _hasActiveFilters() ? Colors.white : AppColors.mutedForeground,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewModeButton(IconData icon, String mode) {
    final isSelected = _viewMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          color: isSelected ? AppColors.primary : Colors.transparent,
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.mutedForeground,
            size: 18,
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedBrandId != null ||
           _selectedCondition != null ||
           _selectedSize != null ||
           _selectedPriceRange != null ||
           _verifiedOnly == true ||
           _minPrice != null ||
           _maxPrice != null;
  }

  Widget _buildItemsView() {
    return Consumer<ItemsService>(
      builder: (context, itemsService, _) {
        if (itemsService.loading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final error = itemsService.error;
        if (error != null && itemsService.items.isEmpty) {
          return SliverFillRemaining(
            child: _buildErrorState(error),
          );
        }

        final filteredItems = _getFilteredItems(itemsService.items);
        
        if (filteredItems.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        if (_viewMode == 'list') {
          return _buildItemsList(filteredItems);
        } else {
          return _buildItemsGrid(filteredItems);
        }
      },
    );
  }

  Widget _buildItemsGrid(List<ItemSummaryResponse> items) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300, // Responsive grid like React FE
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 0.6, // Taller card to prevent overflow (was 0.75)
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return _buildProductCard(item);
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildItemsList(List<ItemSummaryResponse> items) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildProductListCard(item),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(ItemSummaryResponse item) {
    final isLiked = _likedItems.contains(item.itemId);
    final sustainabilityScore = _calculateSustainabilityScore(item);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailPage(itemId: item.itemId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        // Match React FE: hover:shadow-lg transition-shadow
        onTapDown: (_) {},
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.1)),
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
              // Product Image - Match React FE: aspect-square
              AspectRatio(
                aspectRatio: 1.0, // aspect-square
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: item.primaryImageUrl != null
                            ? Image.network(
                                CloudinaryHelper.getMediumImageUrl(item.primaryImageUrl!, width: 600),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.inventory_2_outlined, // Match React FE: Package icon
                                  color: AppColors.mutedForeground,
                                  size: 64,
                                ),
                              )
                            : Icon(
                                Icons.inventory_2_outlined, // Match React FE: Package icon
                                color: AppColors.mutedForeground,
                                size: 64,
                              ),
                      ),
                    ),
                    // Sustainability badge - Match React FE: top-3 left-3 bg-green-100 text-green-800
                    Positioned(
                      top: 12, // top-3
                      left: 12, // left-3
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5), // bg-green-100
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$sustainabilityScore% Sustainable',
                          style: const TextStyle(
                            color: Color(0xFF065F46), // text-green-800
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Like button - Match React FE: top-3 right-3 ghost variant, red when liked
                    Positioned(
                      top: 12, // top-3
                      right: 12, // right-3
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isLiked) {
                                _likedItems.remove(item.itemId);
                              } else {
                                _likedItems.add(item.itemId);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.transparent, // ghost variant
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? AppColors.destructive : AppColors.mutedForeground, // red-500 when liked
                              size: 16, // h-4 w-4
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product Info - Match React FE: CardContent className="p-4" space-y-2
              Padding(
                padding: const EdgeInsets.all(16), // p-4
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - Match React FE: Link href={`/item/${id}`} - Clickable title
                    GestureDetector(
                      onTap: () {
                        // Match React FE: Link navigation to /item/${id}
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailPage(itemId: item.itemId),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque, // Prevent card tap when clicking title
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w500, // font-medium
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2, // line-clamp-2
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8), // space-y-2
                    // Brand • Size • Condition - Match React FE: text-sm text-muted-foreground
                    Row(
                      children: [
                        if (item.brandName != null) ...[
                          Text(
                            item.brandName!,
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12, // text-sm
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        Text(
                          'Size ${item.size}',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _getConditionText(item),
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price and Likes - Match React FE: flex items-center justify-between
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${item.pointValue} points',
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 18, // text-lg
                                fontWeight: FontWeight.bold, // font-bold
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (item.originalPrice != null) ...[
                              const SizedBox(width: 8), // space-x-2
                              Text(
                                '${item.originalPrice} points',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 14, // text-sm
                                  decoration: TextDecoration.lineThrough, // line-through
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: AppColors.mutedForeground,
                              size: 12, // h-3 w-3
                            ),
                            const SizedBox(width: 4), // space-x-1
                            Text(
                              '${item.likeCount}',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12, // text-sm
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Seller and Location - Match React FE: MapPin h-3 w-3 text-sm
                    Row(
                      children: [
                        Icon(
                          Icons.location_on, // MapPin icon
                          color: AppColors.mutedForeground,
                          size: 12, // h-3 w-3
                        ),
                        const SizedBox(width: 8), // space-x-2
                        Expanded(
                          child: Text(
                            '${item.ownerName} • Vietnam',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 12, // text-sm
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // View Details Button - Match React FE: Button asChild Link href={`/item/${id}`}
                    SizedBox(
                      width: double.infinity, // w-full
                      child: ElevatedButton(
                        onPressed: () {
                          // Match React FE: Link navigation to /item/${id}
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailPage(itemId: item.itemId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductListCard(ItemSummaryResponse item) {
    final isLiked = _likedItems.contains(item.itemId);
    final sustainabilityScore = _calculateSustainabilityScore(item);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailPage(itemId: item.itemId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: item.primaryImageUrl != null
                      ? Image.network(
                          CloudinaryHelper.getMediumImageUrl(item.primaryImageUrl!, width: 600),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image,
                            color: AppColors.mutedForeground,
                            size: 40,
                          ),
                        )
                      : Icon(
                          Icons.image,
                          color: AppColors.mutedForeground,
                          size: 40,
                        ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isLiked) {
                                    _likedItems.remove(item.itemId);
                                  } else {
                                    _likedItems.add(item.itemId);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? AppColors.destructive : AppColors.mutedForeground,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$sustainabilityScore% Sustainable',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.brandName ?? ''} • Size ${item.size} • ${_getConditionText(item)}',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.stars_rounded, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.pointValue} points',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.originalPrice != null)
                                Text(
                                  '${item.originalPrice} points',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _addToCart(item),
                            icon: const Icon(Icons.shopping_cart, size: 16),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getConditionText(ItemSummaryResponse item) {
    // Match React FE: conditionText || 'Good'
    // Map condition enum to readable text
    switch (item.condition) {
      case ItemCondition.EXCELLENT:
        return 'Excellent';
      case ItemCondition.GOOD:
        return 'Good';
      case ItemCondition.FAIR:
        return 'Fair';
      case ItemCondition.POOR:
        return 'Poor';
    }
  }

  int _calculateSustainabilityScore(ItemSummaryResponse item) {
    // Match React FE: Math.round((item.conditionScore / 5) * 100) || 75
    // Since we don't have conditionScore, calculate from condition enum
    // EXCELLENT = 100%, GOOD = 85%, FAIR = 70%, POOR = 50%
    switch (item.condition) {
      case ItemCondition.EXCELLENT:
        return 100;
      case ItemCondition.GOOD:
        return 85;
      case ItemCondition.FAIR:
        return 70;
      case ItemCondition.POOR:
        return 50;
    }
  }

  void _addToCart(ItemSummaryResponse item) {
    final cartService = context.read<CartService>();
    cartService.addItem(
      CartItem(
        itemId: item.itemId,
        name: item.name,
        pointValue: item.pointValue,
        imageUrl: item.primaryImageUrl,
        condition: item.condition.toString().split('.').last,
        size: item.size,
        brand: item.brandName,
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item.name} to cart'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: AppColors.mutedForeground,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No products found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search keywords or filters',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategoryId = null;
                  _selectedBrandId = null;
                  _selectedCondition = null;
                  _selectedSize = null;
                  _selectedPriceRange = null;
                  _verifiedOnly = null;
                  _minPrice = null;
                  _maxPrice = null;
                });
                _refreshData();
              },
                      style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(Icons.error_outline, color: AppColors.destructive, size: 64),
            const SizedBox(height: 16),
          Text(
              'An error occurred',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Sort',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
            ),
            ..._sortOptions.map((option) {
              final isSelected = _selectedSort == option;
              return ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.foreground,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedSort = option;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.only(
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
            style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
            ),
          ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBrandId = null;
                          _selectedCondition = null;
                          _selectedSize = null;
                          _selectedPriceRange = null;
                          _verifiedOnly = null;
                          _minPrice = null;
                          _maxPrice = null;
                        });
                      },
                      child: Text(
                        'Clear All',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verified Filter
                        _buildFilterSection(
                          'Status',
                          Column(
                            children: [
                              CheckboxListTile(
                                title: Row(
                                  children: [
                                    Icon(Icons.verified, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Show verified only'),
                                  ],
                                ),
                                value: _verifiedOnly ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    _verifiedOnly = value;
                                  });
                                },
                                activeColor: AppColors.primary,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        // Brand Filter
                        _buildFilterSection(
                          'Brand',
                          Consumer<BrandsService>(
                            builder: (context, brandsService, _) {
                              if (brandsService.loading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              if (brandsService.brands.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'No brands available',
                                    style: TextStyle(color: AppColors.mutedForeground),
                                  ),
                                );
                              }
                              
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: brandsService.brands.map((brand) {
                                  final isSelected = _selectedBrandId == brand.brandId;
                                  return FilterChip(
                                    label: Text(brand.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedBrandId = selected ? brand.brandId : null;
                                      });
                                      // Note: Will reload when filter sheet is closed and "Áp dụng" is pressed
                                    },
                                    backgroundColor: AppColors.muted,
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.foreground,
                                      fontSize: 13,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        // Size Filter
                        _buildFilterSection(
                          'Size',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _sizes.map((size) {
                              final isSelected = _selectedSize == size;
                              return FilterChip(
                                label: Text(size),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedSize = selected ? size : null;
                                  });
                                },
                                backgroundColor: AppColors.muted,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.foreground,
                                  fontSize: 13,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              );
                            }).toList(),
                          ),
                        ),
                        // Condition Filter
                        _buildFilterSection(
                          'Condition',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['EXCELLENT', 'GOOD', 'FAIR', 'POOR'].map((condition) {
                              final isSelected = _selectedCondition == condition;
                              final displayName = {
                                'EXCELLENT': 'Excellent',
                                'GOOD': 'Good',
                                'FAIR': 'Fair',
                                'POOR': 'Poor',
                              }[condition] ?? condition;
                              
                              return FilterChip(
                                label: Text(displayName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCondition = selected ? condition : null;
                                  });
                                },
                                backgroundColor: AppColors.muted,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.foreground,
                                  fontSize: 13,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              );
                            }).toList(),
                          ),
                        ),
                        // Price Range Filter
                        _buildFilterSection(
                          'Price Range (points)',
                          Column(
                            children: _priceRanges.map((range) {
                              final isSelected = _selectedPriceRange == range['label'];
                              return RadioListTile<String>(
                                title: Text(range['label']),
                                value: range['label'],
                                groupValue: _selectedPriceRange,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriceRange = value;
                                  });
                                },
                                activeColor: AppColors.primary,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.mutedForeground,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Reload items with new filters
                          _onFiltersChanged();
            },
            style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
