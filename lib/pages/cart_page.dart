import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'checkout_page.dart';
import 'marketplace_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<CartService, AuthService>(
        builder: (context, cart, auth, _) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - Match React FE
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    
                    if (cart.isEmpty)
                      _buildEmptyCart(context)
                    else
                      _buildCartContent(context, cart, auth),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Header - Match React FE: Continue Shopping button + Shopping Cart title
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Continue Shopping button - Match React FE
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back,
                size: 16,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                'Continue Shopping',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Shopping Cart title - Match React FE
        Row(
          children: [
            Icon(
              Icons.shopping_cart,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Shopping Cart',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Empty Cart - Match React FE
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(64),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from the marketplace to get started!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to marketplace
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketplacePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Browse Marketplace',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cart Content - Match React FE: Grid layout with items and summary
  Widget _buildCartContent(BuildContext context, CartService cart, AuthService auth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 768; // lg breakpoint
        
        if (isWide) {
          // Desktop/Tablet: Side-by-side layout - Match React FE
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cart Items - Match React FE: lg:col-span-2
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCartItem(context, item, cart),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Order Summary - Match React FE: lg:col-span-1 sticky
              SizedBox(
                width: constraints.maxWidth * 0.33,
                child: _buildOrderSummary(context, cart, auth),
              ),
            ],
          );
        } else {
          // Mobile: Stacked layout
          return Column(
            children: [
              // Cart Items
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCartItem(context, item, cart),
              )),
              const SizedBox(height: 24),
              // Order Summary
              _buildOrderSummary(context, cart, auth),
            ],
          );
        }
      },
    );
  }

  // Cart Item - Match React FE design
  Widget _buildCartItem(BuildContext context, CartItem item, CartService cart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image - Match React FE: w-24 h-24
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.mutedForeground,
                        size: 32,
                      ),
                    )
                  : Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.mutedForeground,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Item Details - Match React FE: flex-1
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name - Match React FE: font-semibold text-lg
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Price per item - Match React FE: text-sm text-muted-foreground
                Text(
                  '${item.pointValue} points each',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                // Quantity Controls - Match React FE
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => cart.decreaseQuantity(item.itemId),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => cart.increaseQuantity(item.itemId),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Subtotal & Remove - Match React FE: text-right
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Subtotal - Match React FE: text-lg font-bold
              Text(
                '${item.totalPoints} points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              // Remove button - Match React FE: Trash2 icon
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showRemoveItemDialog(context, item, cart),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.destructive,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Order Summary - Match React FE: Order Summary sidebar
  Widget _buildOrderSummary(BuildContext context, CartService cart, AuthService auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title - Match React FE: text-xl font-semibold
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 24),
          // Summary details - Match React FE: space-y-3
          Column(
            children: [
              // Subtotal - Match React FE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal (${cart.items.length} items)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  Text(
                    '${cart.totalPoints} points',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Shipping - Match React FE: Free
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipping',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tax - Match React FE: 0
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  Text(
                    '0 points',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Divider - Match React FE: border-t
              Divider(color: AppColors.border),
              const SizedBox(height: 12),
              // Total - Match React FE: text-lg font-bold text-primary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  Text(
                    '${cart.totalPoints} points',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Checkout Button - Match React FE: w-full Button with CreditCard icon
          // Button always enabled (only disabled when cart.length === 0) - Match React FE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckoutPage(),
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
                disabledBackgroundColor: AppColors.muted,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Footer text - Match React FE
          Center(
            child: Text(
              'Secure checkout powered by Green Loop',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, CartItem item, CartService cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Product'),
        content: Text('Are you sure you want to remove "${item.name}" from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.removeItem(item.itemId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all products from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartService>().clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

