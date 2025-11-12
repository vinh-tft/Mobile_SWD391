import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/items_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../models/api_models.dart';
import '../utils/cloudinary_helper.dart';
import '../widgets/animated_bottom_nav.dart';
import 'chat_page_redesigned.dart';
import 'marketplace_page.dart';
import 'home_page.dart';
import 'cart_page.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'admin_dashboard_page.dart';

class ItemDetailPage extends StatefulWidget {
  final String itemId;

  const ItemDetailPage({
    super.key,
    required this.itemId,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  ItemResponse? _item;
  bool _loading = true;
  String? _error;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _addingToCart = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadItem();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final itemsService = context.read<ItemsService>();
      final item = await itemsService.getItemById(widget.itemId);
      
      if (item != null) {
        setState(() {
          _item = item;
          _loading = false;
        });
        print('✅ Loaded item: ${item.name}, images: ${item.imageUrls.length}');
      } else {
        setState(() {
          _error = 'Product not found';
          _loading = false;
        });
        print('⚠️ Item not found for ID: ${widget.itemId}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading item: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        _error = 'Error loading product: $e';
        _loading = false;
      });
    }
  }

  List<String> _getItemImages() {
    if (_item == null) return [];
    if (_item!.imageUrls.isNotEmpty) {
      return _item!.imageUrls;
    }
    return [];
  }

  void _addToCart() async {
    if (_item == null) return;

    setState(() {
      _addingToCart = true;
    });

    try {
      final cartService = context.read<CartService>();
      cartService.addItem(
        CartItem(
          itemId: _item!.itemId,
          name: _item!.name,
          pointValue: _item!.pointValue,
          imageUrl: _getItemImages().isNotEmpty ? _getItemImages()[0] : null,
          condition: _getConditionText(),
          size: _item!.size,
          brand: _item!.brandName,
          quantity: 1,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  void _messageSeller() {
    if (_item == null) return;
    
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to send a message'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPageRedesigned(
          sellerName: _item!.ownerName,
          sellerId: _item!.ownerId,
        ),
      ),
    );
  }

  String _getConditionText() {
    if (_item == null) return 'Good';
    switch (_item!.condition) {
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

  int _calculateDiscount() {
    if (_item == null || _item!.originalPrice == null) return 0;
    final originalPrice = _item!.originalPrice!;
    final currentPrice = _item!.pointValue;
    if (originalPrice > currentPrice) {
      return ((1 - currentPrice / originalPrice) * 100).round();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _item == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.foreground),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.mutedForeground),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Product not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Marketplace'),
              ),
            ],
          ),
        ),
      );
    }

    final images = _getItemImages();
    final price = _item!.pointValue;
    final originalPrice = _item!.originalPrice;
    final discount = _calculateDiscount();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          _buildAppBar(),

          // Breadcrumb
          _buildBreadcrumb(),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  _buildImageGallery(images),
                  const SizedBox(height: 24),

                  // Product Info
                  _buildProductInfo(price, originalPrice, discount),
                  const SizedBox(height: 24),

                  // Specifications
                  _buildSpecifications(),
                  const SizedBox(height: 24),

                  // Shipping Info
                  _buildShippingInfo(),
                  const SizedBox(height: 24),

                  // Actions
                  _buildActions(),
                  const SizedBox(height: 24),

                  // Seller Info
                  _buildSellerInfo(),
                  const SizedBox(height: 24),

                  // Tags
                  if (_item!.tags.isNotEmpty) _buildTags(),
                  const SizedBox(height: 24),

                  // Stats
                  _buildStats(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer2<AuthService, CartService>(
      builder: (context, authService, cartService, child) {
        final hasAdminAccess = authService.hasAdminAccess;
        
        // Define navigation items based on role
        final List<BottomNavItem> items = hasAdminAccess
            ? [
                // Staff/Admin navigation (4 tabs - không có Trang chủ)
                const BottomNavItem(icon: Icons.dashboard_rounded, label: 'Manage'),
                const BottomNavItem(icon: Icons.chat_rounded, label: 'Customer Chat'),
                const BottomNavItem(icon: Icons.receipt_long_rounded, label: 'Transactions'),
                BottomNavItem(
                  icon: Icons.person_rounded, 
                  label: authService.isAdmin ? 'Staff' : 'Staff'
                ),
              ]
            : [
                // Customer navigation (5 tabs)
                const BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
                const BottomNavItem(icon: Icons.shopping_bag_rounded, label: 'Item'),
                const BottomNavItem(icon: Icons.shopping_cart_rounded, label: 'Cart'),
                const BottomNavItem(icon: Icons.chat_rounded, label: 'Messages'),
                const BottomNavItem(icon: Icons.person_rounded, label: 'Profile'),
              ];

        // Determine current index based on current route
        int currentIndex = 1; // Default to marketplace/shop
        final route = ModalRoute.of(context);
        if (route != null) {
          // Try to determine from route name or context
          // For now, default to marketplace (index 1)
        }

        return Stack(
          children: [
            AnimatedBottomNav(
              currentIndex: currentIndex,
              onTap: (index) {
                // Navigate based on index - pop back to main and let main handle tab switching
                if (hasAdminAccess) {
                  switch (index) {
                    case 0:
                      // Admin Dashboard (Quản lý) - navigate to admin dashboard
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                      );
                      break;
                    case 1:
                      // Chat với khách hàng - navigate to chat list
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatListPage()),
                      );
                      break;
                    case 2:
                      // Transactions - pop to main
                      Navigator.popUntil(context, (route) => route.isFirst);
                      break;
                    case 3:
                      // Profile - pop to main
                      Navigator.popUntil(context, (route) => route.isFirst);
                      break;
                  }
                } else {
                  switch (index) {
                    case 0:
                      // Home - pop to main
                      Navigator.popUntil(context, (route) => route.isFirst);
                      break;
                    case 1:
                      // Marketplace - pop back to marketplace
                      Navigator.pop(context);
                      break;
                    case 2:
                      // Cart - pop to main, then navigate to cart
                      Navigator.popUntil(context, (route) => route.isFirst);
                      // Note: Main page will handle showing cart page
                      break;
                    case 3:
                      // Chat - pop to main
                      Navigator.popUntil(context, (route) => route.isFirst);
                      break;
                    case 4:
                      // Profile - pop to main
                      Navigator.popUntil(context, (route) => route.isFirst);
                      break;
                  }
                }
              },
              items: items,
              backgroundColor: AppColors.primary,
              indicatorColor: AppColors.primaryLight,
              selectedIconColor: Colors.white,
              unselectedIconColor: AppColors.whiteWithOpacity(0.6),
              animationDuration: const Duration(milliseconds: 300),
            ),
            // Cart Badge (for customers only)
            if (!hasAdminAccess && cartService.itemCount > 0)
              Positioned(
                top: 8,
                left: MediaQuery.of(context).size.width * 0.4 + 20,
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
                  child: Center(
                    child: Text(
                      '${cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.card,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.foreground),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Product Details',
        style: TextStyle(
          color: AppColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? AppColors.destructive : AppColors.foreground,
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.share_outlined, color: AppColors.foreground),
          onPressed: () {
            // Share functionality
          },
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: Text(
                'Home',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ),
            Text(' / ', style: TextStyle(color: AppColors.mutedForeground)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Marketplace',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ),
            Text(' / ', style: TextStyle(color: AppColors.mutedForeground)),
            Expanded(
              child: Text(
                _item?.name ?? '',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(Icons.image, size: 64, color: AppColors.mutedForeground),
        ),
      );
    }

    return Column(
      children: [
        // Main Image
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  // Optimize Cloudinary image URL
                  final imageUrl = CloudinaryHelper.getLargeImageUrl(images[index], width: 1200);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image, size: 64, color: AppColors.mutedForeground),
                      ),
                    ),
                  );
                },
              ),
              // Navigation arrows
              if (images.length > 1) ...[
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      child: IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: () {
                          if (_currentImageIndex > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      child: IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: () {
                          if (_currentImageIndex < images.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
              // Image counter
              if (images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1} / ${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              // Verified badge
              if (_item?.isMarketplaceReady == true)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Thumbnails
        if (images.length > 1)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        CloudinaryHelper.getThumbnailUrl(images[index], size: 200),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.muted,
                          child: Icon(Icons.broken_image, size: 24),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(int price, int? originalPrice, int discount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and badges
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item!.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getConditionText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                      if (_item!.brandName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _item!.brandName!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Price
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$price points',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (originalPrice != null && originalPrice > price) ...[
              const SizedBox(width: 12),
              Text(
                '$originalPrice points',
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.mutedForeground,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.destructive,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-$discount%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          _item!.description.isNotEmpty ? _item!.description : 'No description',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.mutedForeground,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecifications() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              if (_item!.brandName != null)
                _buildSpecItem('Brand', _item!.brandName!),
              if (_item!.size.isNotEmpty)
                _buildSpecItem('Size', _item!.size),
              if (_item!.color.isNotEmpty)
              _buildSpecItem('Color', _item!.color),
              _buildSpecItem('Condition', _getConditionText()),
                _buildSpecItem(
                'Status',
                _item!.status.toString().split('.').last,
                showVerified: _item!.isMarketplaceReady,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, {bool showVerified = false}) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              if (showVerified) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 16, color: AppColors.primary),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Shipping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated delivery: 3-5 business days',
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
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addingToCart ? null : _addToCart,
            icon: _addingToCart
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.shopping_bag, size: 20),
            label: Text(_addingToCart ? 'Adding...' : 'Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _messageSeller,
            icon: const Icon(Icons.message, size: 20),
            label: const Text('Message Seller'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.foreground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _item!.ownerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          'Vietnam',
                          style: TextStyle(
                            fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _item!.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${_item!.viewCount}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Views',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${_item!.likeCount}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Likes',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

