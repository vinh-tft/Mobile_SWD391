import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/cart_service.dart';
import 'checkout_simple_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String title;
  final String price;
  final String rating;
  final String description;
  final List<String> images;
  final String seller;
  final String condition;
  final String size;
  final String brand;

  const ProductDetailPage({
    super.key,
    required this.title,
    required this.price,
    required this.rating,
    required this.description,
    required this.images,
    required this.seller,
    required this.condition,
    required this.size,
    required this.brand,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          _buildAppBar(),
          
          // Image Gallery
          _buildImageGallery(),
          
          // Product Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProductHeader(),
                _buildProductDetails(),
                _buildSellerInfo(),
                _buildDescription(),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      // Floating Checkout Button
      bottomNavigationBar: _buildCheckoutButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
      title: Text(
        'Chi tiết sản phẩm',
          style: TextStyle(
          color: AppColors.foreground,
            fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          ),
          IconButton(
          icon: Icon(Icons.share_outlined, color: AppColors.foreground),
          onPressed: () {
            // Share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Chia sẻ sản phẩm'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primary,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImageGallery() {
    return SliverToBoxAdapter(
      child: Container(
        height: 400,
        color: AppColors.muted,
        child: Stack(
                children: [
            // Image PageView
            PageView.builder(
              itemCount: widget.images.isNotEmpty ? widget.images.length : 1,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return widget.images.isNotEmpty
                    ? Image.network(
                        widget.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage();
              },
            ),
            // Image Indicators
            if (widget.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? AppColors.primary
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                ),
              ),
            // Condition Badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                child: Text(
                  widget.condition,
                    style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.muted,
      child: Center(
                child: Icon(
          Icons.image_outlined,
                  size: 80,
          color: AppColors.mutedForeground,
              ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          if (widget.brand.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                widget.brand.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
              ),
            ),
          ),
          // Title
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Rating
          Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 4),
              Text(
                widget.rating,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(120 đánh giá)',
                style: TextStyle(
                fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Price
          Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                widget.price,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin sản phẩm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Tình trạng', widget.condition, Icons.verified_outlined),
          const Divider(height: 24),
          _buildDetailRow('Kích cỡ', widget.size, Icons.straighten),
          const Divider(height: 24),
          _buildDetailRow('Thương hiệu', widget.brand, Icons.sell_outlined),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
        children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                label,
                  style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 4),
                Text(
                value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
        child: Row(
          children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.seller.isNotEmpty ? widget.seller[0].toUpperCase() : 'S',
                  style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.seller,
                  style: TextStyle(
                    fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.verified, color: AppColors.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Người bán đáng tin cậy',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.mutedForeground, size: 18),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
            'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
              letterSpacing: -0.3,
                    ),
                  ),
          const SizedBox(height: 12),
                  Text(
            widget.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.foreground,
                    ),
                  ),
                ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Consumer<CartService>(
      builder: (context, cart, _) {
        final pointValue = int.tryParse(widget.price.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        final isInCart = cart.isInCart(widget.title); // Using title as itemId for now
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Add to Cart Button
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      if (isInCart) {
                        // Already in cart, show message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Sản phẩm đã có trong giỏ hàng'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      } else {
                        // Add to cart
                        final cartItem = CartItem(
                          itemId: widget.title, // Using title as itemId
                          name: widget.title,
                          pointValue: pointValue,
                          imageUrl: widget.images.isNotEmpty ? widget.images[0] : null,
                          condition: widget.condition,
                          size: widget.size,
                          brand: widget.brand,
                          quantity: 1,
                        );
                        cart.addItem(cartItem);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã thêm vào giỏ hàng'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                            action: SnackBarAction(
                              label: 'Xem',
                              textColor: Colors.white,
                              onPressed: () {
                                // Navigate to cart page
                                Navigator.pushNamed(context, '/cart');
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: isInCart ? AppColors.primary : AppColors.border, width: 2),
                shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Icon(
                      isInCart ? Icons.check_circle : Icons.add_shopping_cart_rounded,
                      color: isInCart ? AppColors.primary : AppColors.foreground,
                      size: 24,
                ),
              ),
            ),
                const SizedBox(width: 12),
                // Buy Now Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Create product map for CheckoutPage
                      final productMap = {
                        'name': widget.title,
                        'price': widget.price,
                        'pointValue': pointValue,
                        'images': widget.images.isNotEmpty ? widget.images : [''],
                        'image': widget.images.isNotEmpty ? widget.images[0] : '',
                        'seller': widget.seller,
                        'condition': widget.condition,
                        'size': widget.size,
                        'brand': widget.brand,
                        'description': widget.description,
                      };
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutSimplePage(
                            product: productMap,
                            quantity: 1,
                          ),
                        ),
                      );
              },
              style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mua ngay',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                ),
              ),
            ),
          ],
            ),
          ),
        );
      },
    );
  }
}
