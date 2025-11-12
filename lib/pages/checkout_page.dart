import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Delivery info controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'TP. Hồ Chí Minh');
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _editing = false;
  
  @override
  void initState() {
    super.initState();
    // Pre-fill user info
    final auth = context.read<AuthService>();
    if (auth.currentUser != null) {
      _nameController.text = auth.currentUser!.name;
      _phoneController.text = auth.currentUser!.phone ?? '';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _calculateTotal(CartService cart) {
    return cart.totalPoints;
  }

  bool _validateDeliveryInfo() {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter full name');
      return false;
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^0\d{9}$').hasMatch(phone)) {
      _showErrorDialog('Please enter a valid phone number (10 digits, starting with 0)');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _showErrorDialog('Please enter delivery address');
      return false;
    }
    return true;
  }

  Future<void> _handleConfirmOrder() async {
    final cart = context.read<CartService>();
    final auth = context.read<AuthService>();
    
    if (cart.isEmpty) {
      Navigator.pop(context);
      return;
    }
    
    // Validate delivery info
    if (!_validateDeliveryInfo()) {
      return;
    }

    final totalAmount = _calculateTotal(cart);
    final userPoints = auth.currentUser?.points ?? 0;

    // Check point balance
    if (userPoints < totalAmount) {
      _showInsufficientModalDialog();
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final api = context.read<ApiClient>();
      
      // Build order request
      final orderData = {
        'buyerId': auth.currentUser!.id,
        'items': cart.items.map((item) => {
          'itemId': item.itemId,
          'quantity': item.quantity,
          'unitPrice': item.pointValue,
          'discount': 0,
          'tax': 0,
        }).toList(),
        'shippingAddress': '${_addressController.text.trim()}, ${_wardController.text.trim()}, ${_districtController.text.trim()}, ${_cityController.text.trim()}',
        'notes': _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : 'Đơn hàng từ marketplace',
      };

      final response = await api.post('/api/orders/checkout', body: orderData);
      
      // Clear cart
      cart.clear();
      
      // Refresh user points
      await auth.refreshPoints();
      
      if (mounted) {
        final orders = response is List ? response : (response['data'] ?? []);
        final orderCount = orders is List ? orders.length : 1;
        
        _showSuccessDialog(orderCount);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Unable to complete order. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<CartService, AuthService>(
        builder: (context, cart, auth, _) {
          if (cart.isEmpty) {
            // Redirect to cart if empty
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final totalAmount = _calculateTotal(cart);
          final userPoints = auth.currentUser?.points ?? 0;
          final shippingFee = 0; // Free shipping
          final finalTotal = totalAmount + shippingFee;

          return SafeArea(
            child: Column(
              children: [
                // Header - Match React FE
                _buildHeader(),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 768;
                        
                        if (isWide) {
                          // Desktop/Tablet: Side-by-side layout - Match React FE
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column - Delivery & Items - Match React FE: lg:col-span-2
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildDeliveryCard(),
                                    const SizedBox(height: 24),
                                    _buildCartItemsCard(cart),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right Column - Order Summary - Match React FE: lg:col-span-1
                              SizedBox(
                                width: constraints.maxWidth * 0.33,
                                child: _buildOrderSummary(cart, auth, finalTotal, userPoints),
                              ),
                            ],
                          );
                        } else {
                          // Mobile: Stacked layout
                          return Column(
                            children: [
                              _buildDeliveryCard(),
                              const SizedBox(height: 24),
                              _buildCartItemsCard(cart),
                              const SizedBox(height: 24),
                              _buildOrderSummary(cart, auth, finalTotal, userPoints),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInsufficientModalDialog() {
    final cart = context.read<CartService>();
    final auth = context.read<AuthService>();
    
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInsufficientModal(cart, auth),
    );
  }

  // Header - Match React FE
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title - Match React FE: text-3xl font-bold
          Text(
            'Confirm Order',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          // Description - Match React FE: text-muted-foreground
          Text(
            'Review information before placing order',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  // Delivery Information Card - Match React FE
  Widget _buildDeliveryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button - Match React FE
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Delivery Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _editing = !_editing);
                  },
                  icon: Icon(
                    _editing ? Icons.close : Icons.edit,
                    size: 16,
                  ),
                  label: Text(_editing ? 'Cancel' : 'Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _editing ? _buildDeliveryForm() : _buildDeliveryView(),
          ),
        ],
      ),
    );
  }

  // Delivery Form - Match React FE editing mode
  Widget _buildDeliveryForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField('Full Name *', _nameController, Icons.person_outline),
          const SizedBox(height: 16),
          _buildFormField('Phone Number *', _phoneController, Icons.phone_outlined,
              keyboardType: TextInputType.phone, maxLength: 10),
          const SizedBox(height: 16),
          _buildFormField('Address *', _addressController, Icons.home_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFormField('Ward/Commune', _wardController, Icons.location_city)),
              const SizedBox(width: 16),
              Expanded(child: _buildFormField('District', _districtController, Icons.map_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormField('Notes', _notesController, Icons.note_outlined, maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _editing = false);
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Save Information'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delivery View - Match React FE view mode
  Widget _buildDeliveryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDeliveryInfoRow('Recipient', _nameController.text.isNotEmpty ? _nameController.text : 'Not updated'),
        const SizedBox(height: 12),
        _buildDeliveryInfoRow('Phone Number', _phoneController.text.isNotEmpty ? _phoneController.text : 'Not updated'),
        const SizedBox(height: 12),
        _buildDeliveryInfoRow(
          'Address',
          _addressController.text.isNotEmpty
              ? '${_addressController.text}, ${_wardController.text}, ${_districtController.text}, ${_cityController.text}'
              : 'Not updated',
        ),
        if (_notesController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDeliveryInfoRow('Notes', _notesController.text),
        ],
      ],
    );
  }

  Widget _buildDeliveryInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1, int? maxLength}) {
    final isRequired = label.contains('*');
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter ${label.replaceAll('*', '').trim()}';
              }
              if (label.contains('Phone Number') && !RegExp(r'^0\d{9}$').hasMatch(value.trim())) {
                return 'Invalid phone number';
              }
              return null;
            }
          : null,
    );
  }

  // Cart Items Card - Match React FE
  Widget _buildCartItemsCard(CartService cart) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Products (${cart.items.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: cart.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Item Image - Match React FE: w-20 h-20
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: AppColors.muted,
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
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.foreground,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(item.pointValue * item.quantity).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Order Summary - Match React FE
  Widget _buildOrderSummary(CartService cart, AuthService auth, int finalTotal, int userPoints) {
    final totalAmount = _calculateTotal(cart);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title - Match React FE
          Row(
            children: [
              Icon(Icons.credit_card, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Point Balance - Match React FE: bg-primary/10
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Point Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${userPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Price Summary - Match React FE: border-t pt-4
          Divider(color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
              Text(
                '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Fee',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
              Text(
                'Free',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border),
          const SizedBox(height: 16),
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
                '${finalTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Point Check Warning - Match React FE
          if (userPoints < finalTotal)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.destructive.withOpacity(0.1),
                border: Border.all(color: AppColors.destructive.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insufficient Points',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.destructive,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You need ${(finalTotal - userPoints).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} more points',
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
            ),
          if (userPoints < finalTotal) const SizedBox(height: 20),
          // Confirm Button - Match React FE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleConfirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: userPoints >= finalTotal ? AppColors.primary : AppColors.muted,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: AppColors.muted,
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Processing...'),
                      ],
                    )
                  : Text(
                      userPoints >= finalTotal ? 'Confirm Order' : 'Insufficient Points',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Footer text - Match React FE
          Center(
            child: Text(
              'By placing an order, you agree to the terms of service',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Insufficient Points Modal - Match React FE
  Widget _buildInsufficientModal(CartService cart, AuthService auth) {
    final totalAmount = _calculateTotal(cart);
    final userPoints = auth.currentUser?.points ?? 0;
    final finalTotal = totalAmount;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Insufficient Points for Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You need ${finalTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points to complete this order.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current balance: ${userPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Shortage: ${(finalTotal - userPoints).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} points',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.destructive,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(int orderCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$orderCount order(s) have been created.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close checkout
                // Navigate to orders page if exists, otherwise go to home
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Complete'),
            ),
          ),
        ],
      ),
    );
  }
}

