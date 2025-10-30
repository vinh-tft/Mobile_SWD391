import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/points_service.dart';
import '../services/items_service.dart';
import '../services/clothing_service.dart';
import '../models/transaction.dart';
import '../models/api_models.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;

  const CheckoutPage({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  // Address form
  final _addressFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Payment
  String _selectedPaymentMethod = 'cod';
  bool _agreeToTerms = false;
  
  // Delivery options
  String _selectedDelivery = 'standard';
  
  final List<Map<String, dynamic>> _deliveryOptions = [
    {
      'id': 'standard',
      'name': 'Giao hàng tiêu chuẩn',
      'description': '3-5 ngày làm việc',
      'price': 0,
      'icon': Icons.local_shipping,
    },
    {
      'id': 'express',
      'name': 'Giao hàng nhanh',
      'description': '1-2 ngày làm việc',
      'price': 50000,
      'icon': Icons.flash_on,
    },
    {
      'id': 'same_day',
      'name': 'Giao trong ngày',
      'description': 'Trong ngày (nếu đặt trước 14h)',
      'price': 100000,
      'icon': Icons.schedule,
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cod',
      'name': 'Thanh toán khi nhận hàng (COD)',
      'description': 'Thanh toán bằng tiền mặt khi nhận hàng',
      'icon': Icons.money,
      'fee': 0,
    },
    {
      'id': 'bank_transfer',
      'name': 'Chuyển khoản ngân hàng',
      'description': 'Chuyển khoản qua ngân hàng',
      'icon': Icons.account_balance,
      'fee': 0,
    },
    {
      'id': 'momo',
      'name': 'Ví MoMo',
      'description': 'Thanh toán qua ví điện tử MoMo',
      'icon': Icons.account_balance_wallet,
      'fee': 0,
    },
    {
      'id': 'vnpay',
      'name': 'VNPay',
      'description': 'Thanh toán qua VNPay',
      'icon': Icons.payment,
      'fee': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill some demo data
    _nameController.text = 'Nguyễn Văn A';
    _phoneController.text = '0123456789';
    _addressController.text = '123 Đường ABC';
    _cityController.text = 'Hồ Chí Minh';
    _districtController.text = 'Quận 1';
    _wardController.text = 'Phường Bến Nghé';

    // Rebuild when users edit to refresh the enabled state of the Continue button
    void addListener(TextEditingController c) => c.addListener(() => setState(() {}));
    addListener(_nameController);
    addListener(_phoneController);
    addListener(_addressController);
    addListener(_cityController);
    addListener(_districtController);
    addListener(_wardController);
    addListener(_noteController);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildAddressStep(),
                  _buildDeliveryStep(),
                  _buildPaymentStep(),
                  _buildConfirmationStep(),
                ],
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildProgressStep(0, 'Địa chỉ', Icons.location_on),
          _buildProgressLine(),
          _buildProgressStep(1, 'Giao hàng', Icons.local_shipping),
          _buildProgressLine(),
          _buildProgressStep(2, 'Thanh toán', Icons.payment),
          _buildProgressLine(),
          _buildProgressStep(3, 'Xác nhận', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive ? Colors.white : const Color(0xFF6B7280),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine() {
    return Container(
      height: 2,
      width: 20,
      color: _currentStep > 0 ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _addressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            
            // Contact info
            _buildSectionTitle('Thông tin liên hệ'),
            _buildTextField(
              controller: _nameController,
              label: 'Họ và tên',
              hint: 'Nhập họ và tên người nhận',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hint: 'Nhập số điện thoại',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (value.length < 10) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Address info
            _buildSectionTitle('Địa chỉ giao hàng'),
            _buildTextField(
              controller: _addressController,
              label: 'Địa chỉ chi tiết',
              hint: 'Số nhà, tên đường',
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập địa chỉ chi tiết';
                }
                return null;
              },
            ),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'Tỉnh/Thành phố',
                    hint: 'Chọn tỉnh/thành phố',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn tỉnh/thành phố';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _districtController,
                    label: 'Quận/Huyện',
                    hint: 'Chọn quận/huyện',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn quận/huyện';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            _buildTextField(
              controller: _wardController,
              label: 'Phường/Xã',
              hint: 'Chọn phường/xã',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng chọn phường/xã';
                }
                return null;
              },
            ),
            
            _buildTextField(
              controller: _noteController,
              label: 'Ghi chú (tùy chọn)',
              hint: 'Ghi chú thêm cho đơn hàng',
              maxLines: 3,
            ),
            
            const SizedBox(height: 20),
            
            // Save address option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.save,
                    color: const Color(0xFF22C55E),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lưu địa chỉ này cho lần mua tiếp theo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: (value) {},
                    activeColor: const Color(0xFF22C55E),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phương thức giao hàng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          ..._deliveryOptions.map((option) => _buildDeliveryOption(option)).toList(),
          
          const SizedBox(height: 20),
          
          // Delivery info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF22C55E),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Thời gian giao hàng có thể thay đổi tùy theo tình hình thực tế',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
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

  Widget _buildDeliveryOption(Map<String, dynamic> option) {
    final isSelected = _selectedDelivery == option['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDelivery = option['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option['icon'],
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if ((option['price'] as int) > 0)
                Text(
                  '+${_formatCurrency(option['price'] as int)} VND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF1F2937),
                  ),
                )
              else
                const Text(
                  'Miễn phí',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22C55E),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          ..._paymentMethods.map((method) => _buildPaymentMethod(method)).toList(),
          
          const SizedBox(height: 20),
          
          // Terms and conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tôi đồng ý với các điều khoản và điều kiện của Green Loop',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
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

  Widget _buildPaymentMethod(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method['icon'],
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if ((method['fee'] as int) > 0)
                Text(
                  '+${_formatCurrency(method['fee'] as int)} VND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF1F2937),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    final deliveryOption = _deliveryOptions.firstWhere((option) => option['id'] == _selectedDelivery);
    final paymentMethod = _paymentMethods.firstWhere((method) => method['id'] == _selectedPaymentMethod);
    final productPrice = int.parse(widget.product['price'].replaceAll(RegExp(r'[^\d]'), ''));
    final totalPrice = productPrice + (deliveryOption['price'] as int) + (paymentMethod['fee'] as int);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xác nhận đơn hàng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          // Product info
          _buildSectionTitle('Sản phẩm'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (widget.product['images'] is List && (widget.product['images'] as List).isNotEmpty)
                      ? Image.network(
                          (widget.product['images'] as List).first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.broken_image,
                              color: Color(0xFF6B7280),
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.image,
                            color: Color(0xFF6B7280),
                            size: 40,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số lượng: ${widget.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product['price'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Delivery info
          _buildSectionTitle('Thông tin giao hàng'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Người nhận: ${_nameController.text}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SĐT: ${_phoneController.text}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Địa chỉ: ${_addressController.text}, ${_wardController.text}, ${_districtController.text}, ${_cityController.text}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      deliveryOption['icon'],
                      color: const Color(0xFF22C55E),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      deliveryOption['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Payment summary
          _buildSectionTitle('Tổng thanh toán'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildPriceRow('Giá sản phẩm', widget.product['price']),
                _buildPriceRow('Phí giao hàng', (deliveryOption['price'] as int) > 0 ? '+${_formatCurrency(deliveryOption['price'] as int)} VND' : 'Miễn phí'),
                if ((paymentMethod['fee'] as int) > 0)
                  _buildPriceRow('Phí thanh toán', '+${_formatCurrency(paymentMethod['fee'] as int)} VND'),
                const Divider(),
                _buildPriceRow('Tổng cộng', '${_formatCurrency(totalPrice)} VND', isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF22C55E) : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF22C55E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _currentStep == 3 ? 'Đặt hàng' : 'Tiếp tục',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _addressFormKey.currentState?.validate() ?? false;
      case 1:
        return _selectedDelivery.isNotEmpty;
      case 2:
        return _selectedPaymentMethod.isNotEmpty && _agreeToTerms;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _placeOrder();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _placeOrder() async {
    // Lấy context provider
    final authService = Provider.of<AuthService>(context, listen: false);
    final pointsService = Provider.of<PointsService>(context, listen: false);
    final itemsService = Provider.of<ItemsService>(context, listen: false);
    final clothingService = Provider.of<ClothingService>(context, listen: false);
    final user = authService.currentUser;
    
    final productPrice = int.tryParse(widget.product['price']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
    // Lấy itemId từ props truyền vào product (nên sửa source từ marketplace truyền cả itemId sang)
    final String? itemId = widget.product['itemId'] ?? null;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tìm thấy thông tin người dùng'), backgroundColor: Colors.red));
      return;
    }
    if (user.points < productPrice) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn không đủ điểm để mua sản phẩm này!'), backgroundColor: Colors.red));
      return;
    }
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thiếu mã sản phẩm!'), backgroundColor: Colors.red));
      return;
    }
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E))),
      ),
    );
    try {
      // Trừ điểm user (API, backend sẽ lưu lịch sử transaction thực)
      final pointSuccess = await pointsService.adjustPoints(userId: user.id, amount: -productPrice, reason: 'buy_item');
      if (!pointSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Giao dịch thất bại khi trừ điểm!'), backgroundColor: Colors.red));
        return;
      }
      // Đánh dấu item SOLD (API)
      final soldSuccess = await itemsService.updateItemStatus(itemId, ItemStatus.SOLD);
      if (!soldSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể cập nhật trạng thái sản phẩm!'), backgroundColor: Colors.red));
        return;
      }
      // Lưu transaction local (nếu muốn demo) hoặc backend sẽ có
      clothingService.createTransaction(Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: user.id,
        staffId: null,
        type: TransactionType.buy,
        status: TransactionStatus.completed,
        clothingItemIds: [itemId],
        totalPoints: productPrice,
        notes: 'Khách mua hàng',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      ));
      // Đặt hàng thành công
      Navigator.pop(context); // Close loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 32),
              SizedBox(width: 12),
              Text('Đặt hàng thành công!'),
            ],
          ),
          content: const Text('Đơn hàng của bạn đã được xác nhận. Chúng tôi sẽ liên hệ với bạn trong thời gian sớm nhất.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to marketplace
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }
}
