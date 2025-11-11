import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../theme/app_colors.dart';

class CheckoutSimplePage extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;

  const CheckoutSimplePage({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  State<CheckoutSimplePage> createState() => _CheckoutSimplePageState();
}

class _CheckoutSimplePageState extends State<CheckoutSimplePage> {
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

  int get totalPoints {
    if (widget.product['items'] != null) {
      // Cart checkout
      return widget.product['totalPoints'] ?? 0;
    }
    // Single item checkout
    return (widget.product['pointValue'] ?? 0) * widget.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thanh toán',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          final userPoints = auth.currentUser?.points ?? 0;
          final sufficient = userPoints >= totalPoints;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary
                        _buildOrderSummary(),
                        const SizedBox(height: 20),
                        
                        // Delivery Information
                        _buildDeliveryForm(),
                        const SizedBox(height: 20),
                        
                        // Points Summary
                        _buildPointsSummary(userPoints, sufficient),
                      ],
                    ),
                  ),
                ),
              ),
              // Checkout Button
              _buildCheckoutButton(auth, sufficient),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Đơn hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.product['items'] != null)
            ..._buildCartItems()
          else
            _buildSingleItem(),
        ],
      ),
    );
  }

  List<Widget> _buildCartItems() {
    final items = widget.product['items'] as List<dynamic>;
    return items.map<Widget>((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.muted,
                child: item['imageUrl'] != null
                    ? Image.network(item['imageUrl'], fit: BoxFit.cover)
                    : Icon(Icons.image, color: AppColors.mutedForeground),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'x${item['quantity']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${item['pointValue'] * item['quantity']} đ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSingleItem() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            color: AppColors.muted,
            child: widget.product['image'] != null && widget.product['image'].toString().isNotEmpty
                ? Image.network(widget.product['image'], fit: BoxFit.cover)
                : Icon(Icons.image, color: AppColors.mutedForeground),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product['name'] ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'x${widget.quantity}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${totalPoints} đ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Thông tin giao hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField('Họ và tên', _nameController, Icons.person_outline, required: true),
          const SizedBox(height: 12),
          _buildTextField('Số điện thoại', _phoneController, Icons.phone_outlined, 
            keyboardType: TextInputType.phone, required: true),
          const SizedBox(height: 12),
          _buildTextField('Địa chỉ', _addressController, Icons.home_outlined, required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('Quận/Huyện', _districtController, Icons.map_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Phường/Xã', _wardController, Icons.location_city)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('Ghi chú', _notesController, Icons.note_outlined, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.mutedForeground),
      ),
      validator: required ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập $label';
        }
        return null;
      } : null,
    );
  }

  Widget _buildPointsSummary(int userPoints, bool sufficient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng điểm thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.stars_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '$totalPoints',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số dư hiện tại',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.mutedForeground,
                ),
              ),
              Text(
                '$userPoints điểm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: sufficient ? AppColors.foreground : AppColors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sau giao dịch',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.mutedForeground,
                ),
              ),
              Text(
                '${userPoints - totalPoints} điểm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: sufficient ? AppColors.success : AppColors.destructive,
                ),
              ),
            ],
          ),
          if (!sufficient)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Không đủ điểm. Vui lòng nạp thêm ${totalPoints - userPoints} điểm.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(AuthService auth, bool sufficient) {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: sufficient && !_isLoading ? _handleConfirmOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              disabledBackgroundColor: AppColors.muted,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        sufficient ? 'Xác nhận đặt hàng' : 'Không đủ điểm',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmOrder() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate phone number
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      _showErrorDialog('Số điện thoại không hợp lệ. Vui lòng nhập 10 số, bắt đầu bằng 0.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate API call (replace with real API later)
      await Future.delayed(const Duration(seconds: 2));

      // Deduct points
      final auth = context.read<AuthService>();
      final success = auth.deductPoints(totalPoints);

      if (success) {
        // Clear cart if it's a cart checkout
        if (widget.product['items'] != null) {
          context.read<CartService>().clear();
        }

        // Show success and navigate
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        _showErrorDialog('Giao dịch thất bại. Vui lòng thử lại.');
      }
    } catch (e) {
      _showErrorDialog('Đã xảy ra lỗi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
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
              'Đặt hàng thành công!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Đơn hàng của bạn đã được xác nhận',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
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
                Navigator.pop(context); // Close product detail
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hoàn tất'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.destructive),
            const SizedBox(width: 8),
            const Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}



