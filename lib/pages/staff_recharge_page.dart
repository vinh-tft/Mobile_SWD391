import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/clothing_service.dart';
import '../services/users_service.dart';
import '../services/points_service.dart';

class StaffRechargePage extends StatefulWidget {
  const StaffRechargePage({super.key});

  @override
  State<StaffRechargePage> createState() => _StaffRechargePageState();
}

class _StaffRechargePageState extends State<StaffRechargePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customerEmailController = TextEditingController();
  int _selectedAmount = 0;
  bool _isLoading = false;

  final List<int> _quickAmounts = [500, 1000, 2000, 5000, 10000];
  String? _selectedPaymentMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'name': 'Tiền mặt',
      'icon': Icons.money,
      'color': const Color(0xFF22C55E),
    },
    {
      'id': 'momo',
      'name': 'Ví MoMo',
      'icon': Icons.phone_android,
      'color': const Color(0xFFD82D8B),
    },
    {
      'id': 'zalopay',
      'name': 'ZaloPay',
      'icon': Icons.payment,
      'color': const Color(0xFF0068FF),
    },
    {
      'id': 'banking',
      'name': 'Chuyển khoản ngân hàng',
      'icon': Icons.account_balance,
      'color': const Color(0xFF3B82F6),
    },
  ];

  // Mock customer data
  final List<Map<String, dynamic>> _customers = [
    {
      'id': '1',
      'name': 'Nguyễn Văn A',
      'email': 'customer@demo.com',
      'phone': '0123456789',
      'points': 1000,
    },
    {
      'id': '2',
      'name': 'Trần Thị B',
      'email': 'tranthi.b@email.com',
      'phone': '0987654321',
      'points': 2500,
    },
    {
      'id': '3',
      'name': 'Lê Văn C',
      'email': 'levan.c@email.com',
      'phone': '0369258147',
      'points': 800,
    },
  ];

  String? _selectedCustomerId;

  @override
  void dispose() {
    _amountController.dispose();
    _customerEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nạp điểm cho khách hàng',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Selection
            const Text(
              'Chọn khách hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomerSelection(),

            const SizedBox(height: 32),

            // Selected Customer Info
            if (_selectedCustomerId != null) _buildCustomerInfo(),

            const SizedBox(height: 32),

            // Amount Selection
            const Text(
              'Chọn số điểm nạp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAmountSelection(),

            const SizedBox(height: 24),

            // Custom Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số điểm',
                hintText: 'Nhập số điểm muốn nạp',
                prefixIcon: const Icon(Icons.stars, color: Color(0xFF22C55E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
                ),
              ),
              onChanged: (value) {
                final amount = int.tryParse(value);
                if (amount != null) {
                  setState(() {
                    _selectedAmount = amount;
                  });
                }
              },
            ),

            const SizedBox(height: 32),

            // Payment Method Selection
            const Text(
              'Chọn phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodSelection(),

            const SizedBox(height: 32),

            // Recharge Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedCustomerId != null && _selectedAmount > 0 && _selectedPaymentMethod != null && !_isLoading 
                    ? _handleRecharge 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                    : const Text(
                        'Nạp điểm cho khách hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hướng dẫn nạp điểm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Chọn khách hàng từ danh sách hoặc tìm kiếm\n'
                    '• Nhập số điểm muốn nạp (tối thiểu 100 điểm)\n'
                    '• Xác nhận thông tin trước khi nạp\n'
                    '• Điểm sẽ được cộng vào tài khoản khách hàng ngay lập tức',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return Column(
      children: [
        // Search Field
        TextField(
          controller: _customerEmailController,
          decoration: InputDecoration(
            labelText: 'Tìm kiếm khách hàng',
            hintText: 'Nhập email hoặc tên khách hàng',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        
        // Customer List
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            itemCount: _getFilteredCustomers().length,
            itemBuilder: (context, index) {
              final customer = _getFilteredCustomers()[index];
              final isSelected = _selectedCustomerId == customer['id'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCustomerId = customer['id'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF22C55E).withOpacity(0.1)
                        : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isSelected 
                            ? const Color(0xFF22C55E)
                            : Colors.grey[300],
                        child: Text(
                          customer['name'][0],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              customer['email'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${customer['points']} điểm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF22C55E),
                              size: 20,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    final customer = _customers.firstWhere(
      (c) => c['id'] == _selectedCustomerId,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              customer['name'][0],
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer['email'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.stars,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${customer['points']} điểm hiện tại',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountSelection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _quickAmounts.length,
      itemBuilder: (context, index) {
        final amount = _quickAmounts[index];
        final isSelected = _selectedAmount == amount;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAmount = amount;
              _amountController.text = amount.toString();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF22C55E).withOpacity(0.1)
                  : Colors.grey[100],
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFF22C55E)
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} điểm',
                style: TextStyle(
                  color: isSelected 
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: isSelected 
                      ? FontWeight.bold 
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method['id'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method['id'];
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (method['color'] as Color).withOpacity(0.1)
                    : Colors.grey[100],
                border: Border.all(
                  color: isSelected 
                      ? method['color'] as Color
                      : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (method['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      color: method['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      method['name'] as String,
                      style: TextStyle(
                        color: isSelected 
                            ? method['color'] as Color
                            : const Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: isSelected 
                            ? FontWeight.bold 
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: method['color'] as Color,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getFilteredCustomers() {
    final query = _customerEmailController.text.toLowerCase();
    if (query.isEmpty) return _customers;
    
    return _customers.where((customer) {
      return customer['name'].toLowerCase().contains(query) ||
             customer['email'].toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _handleRecharge() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khách hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điểm hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số điểm tối thiểu là 100 điểm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phương thức thanh toán'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hiển thị dialog xác nhận
    final confirmed = await _showConfirmationDialog(amount);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    // Gọi API: tìm user theo email, sau đó adjust points
    final usersService = Provider.of<UsersService>(context, listen: false);
    final pointsService = Provider.of<PointsService>(context, listen: false);

    // Lấy email từ customer selected (mock list)
    final selected = _customers.firstWhere((c) => c['id'] == _selectedCustomerId);
    final email = selected['email'] as String;
    final user = await usersService.getByEmail(email);

    if (user == null || user['id'] == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy người dùng trên hệ thống'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ok = await pointsService.adjustPoints(
      userId: user['id'].toString(),
      amount: amount,
      reason: 'staff_recharge_${_selectedPaymentMethod ?? 'unknown'}',
    );

    setState(() => _isLoading = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nạp điểm thất bại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nạp thành công $amount điểm cho khách hàng!'),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );

    // Reset form
    _amountController.clear();
    setState(() {
      _selectedAmount = 0;
      _selectedPaymentMethod = null;
    });
  }

  Future<bool> _showConfirmationDialog(int amount) async {
    final customer = _customers.firstWhere(
      (c) => c['id'] == _selectedCustomerId,
    );
    
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
    );

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nạp điểm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Customer Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF22C55E),
                    child: Text(
                      customer['name'][0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} điểm',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment Method Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (selectedMethod['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedMethod['icon'] as IconData,
                    color: selectedMethod['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedMethod['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: selectedMethod['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn có chắc chắn muốn nạp điểm cho khách hàng này không?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedMethod['color'] as Color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ?? false;
  }
}
