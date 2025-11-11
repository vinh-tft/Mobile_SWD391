import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/items_service.dart';
import '../services/categories_service.dart';
import '../services/brands_service.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';
import 'create_listing_page.dart';
import 'add_category_page.dart';
import 'add_brand_page.dart';
import 'product_detail_page.dart';
import 'add_sale_item_page.dart';

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
  bool? _verifiedOnly;
  int? _minPrice;
  int? _maxPrice;
  
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

  Future<void> _loadData() async {
    await Future.wait([
      context.read<ItemsService>().loadMarketplaceReady(),
      context.read<CategoriesService>().loadActiveCategories(),
      context.read<BrandsService>().loadActiveBrands(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _searchItems() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      await context.read<ItemsService>().searchItems(query);
    } else {
      await context.read<ItemsService>().loadMarketplaceReady();
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
        item.condition.toString().split('.').last == _selectedCondition
      ).toList();
    }

    // Filter by verified status
    if (_verifiedOnly == true) {
      filtered = filtered.where((item) => item.status == ItemStatus.VERIFIED).toList();
    }

    // Filter by price range
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
                
                // Sort and Filter Bar
                _buildSortFilterBar(),
                
                // Items Grid
                _buildItemsGrid(),
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
      label: const Text('Thêm sản phẩm', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildHeader(AuthService authService) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.card,
      elevation: 0,
      title: Row(
              children: [
                Container(
            width: 36,
            height: 36,
                  decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.recycling, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
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
      actions: [
        // Points badge
              Container(
                margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
            color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
                    Text(
                '${authService.currentUser?.points ?? 0}',
                style: TextStyle(
                  color: AppColors.accentForeground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        // Staff actions
              if (authService.isStaff) ...[
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.mutedForeground),
            onSelected: (value) {
              switch (value) {
                case 'add_item':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingPage()));
                  break;
                case 'add_category':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCategoryPage()));
                  break;
                case 'add_brand':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBrandPage()));
                  break;
                case 'add_sale':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSaleItemPage()));
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'add_item', child: Text('Thêm sản phẩm')),
              const PopupMenuItem(value: 'add_category', child: Text('Thêm danh mục')),
              const PopupMenuItem(value: 'add_brand', child: Text('Thêm thương hiệu')),
              const PopupMenuItem(value: 'add_sale', child: Text('Thêm sale')),
            ],
          ),
        ] else
                const SizedBox(width: 8),
              ],
    );
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
                    hintText: 'Tìm kiếm sản phẩm...',
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
                      label: const Text('Tất cả'),
                      selected: isSelected,
                      onSelected: (selected) {
                setState(() {
                          _selectedCategoryId = null;
                });
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
                  '${filteredItems.length} sản phẩm',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
              children: [
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

  bool _hasActiveFilters() {
    return _selectedBrandId != null ||
           _selectedCondition != null ||
           _verifiedOnly == true ||
           _minPrice != null ||
           _maxPrice != null;
  }

  Widget _buildItemsGrid() {
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

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = filteredItems[index];
                return _buildProductCard(item);
              },
              childCount: filteredItems.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ItemSummaryResponse item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              title: item.name,
              price: '${item.pointValue} điểm',
              rating: '4.5',
              description: item.description,
                images: item.primaryImageUrl != null ? [item.primaryImageUrl!] : [],
                seller: item.ownerName,
                condition: item.condition.toString().split('.').last,
              size: item.size,
                brand: item.brandName ?? '',
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
                child: Stack(
                  children: [
                    Container(
                width: double.infinity,
                decoration: BoxDecoration(
                        color: AppColors.muted,
                  borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                  ),
                ),
                      child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                      ),
                        child: item.primaryImageUrl != null
                          ? Image.network(
                                item.primaryImageUrl!,
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
                    // Condition badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.condition.toString().split('.').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                        style: TextStyle(
                          color: AppColors.foreground,
                        fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                      const SizedBox(height: 6),
                      if (item.brandName != null)
                        Text(
                          item.brandName!,
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                          Icon(Icons.stars_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.pointValue} điểm',
                              style: TextStyle(
                                color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Container(
                            padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppColors.primary,
                            size: 12,
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
              'Không tìm thấy sản phẩm',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử điều chỉnh từ khóa tìm kiếm hoặc bộ lọc',
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
              child: const Text('Xóa bộ lọc'),
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
              'Đã xảy ra lỗi',
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
              child: const Text('Thử lại'),
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
                'Sắp xếp',
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
                      'Bộ lọc',
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
                  _verifiedOnly = null;
                  _minPrice = null;
                  _maxPrice = null;
                });
              },
                      child: Text(
                        'Xóa tất cả',
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
                          'Trạng thái',
                          Column(
                            children: [
                              CheckboxListTile(
                                title: Row(
                                  children: [
                                    Icon(Icons.verified, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Chỉ hiển thị đã xác minh'),
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
                          'Thương hiệu',
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
                                    'Không có thương hiệu nào',
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
                        // Condition Filter
                        _buildFilterSection(
                          'Tình trạng',
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['EXCELLENT', 'GOOD', 'FAIR', 'POOR'].map((condition) {
                              final isSelected = _selectedCondition == condition;
                              final displayName = {
                                'EXCELLENT': 'Xuất sắc',
                                'GOOD': 'Tốt',
                                'FAIR': 'Khá',
                                'POOR': 'Cần sửa',
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
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
            },
            style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Áp dụng'),
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
