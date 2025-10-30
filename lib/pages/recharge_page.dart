import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/points_service.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final TextEditingController _amountController = TextEditingController();
  int _selectedAmount = 0;
  bool _isLoading = false;
  String? _selectedPaymentMethod;

  final List<int> _quickAmounts = [500, 1000, 2000, 5000, 10000];
  
  final List<Map<String, dynamic>> _paymentMethods = [
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
      'color': const Color(0xFF22C55E),
    },
    {
      'id': 'cash',
      'name': 'Thanh toán tại cửa hàng',
      'icon': Icons.store,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
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
          'Nạp điểm',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Points Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Số điểm hiện tại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${authService.currentUser?.points ?? 0} điểm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Amount Selection
                const Text(
                  'Chọn số điểm nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
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
                ),

                const SizedBox(height: 32),

                // Custom Amount Input
                const Text(
                  'Hoặc nhập số điểm tùy chỉnh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
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
                Column(
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
                ),

                const SizedBox(height: 32),

                // Recharge Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRecharge,
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
                            'Nạp điểm',
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
                            'Thông tin nạp điểm',
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
                        '• Điểm được nạp ngay lập tức vào tài khoản\n'
                        '• Điểm có thể dùng để mua quần áo trong cửa hàng\n'
                        '• Điểm không có thời hạn sử dụng\n'
                        '• Liên hệ hỗ trợ nếu gặp vấn đề',
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
          );
        },
      ),
    );
  }

  Future<void> _handleRecharge() async {
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

    // Hiển thị dialog xác nhận thanh toán
    final confirmed = await _showPaymentConfirmationDialog(amount);
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final pointsService = Provider.of<PointsService>(context, listen: false);

    final userId = authService.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy người dùng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await pointsService.adjustPoints(
      userId: userId,
      amount: amount,
      reason: 'recharge_${_selectedPaymentMethod ?? 'unknown'}',
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Update local points immediately (defensive in case backend mock skips it)
      authService.addPoints(amount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nạp thành công $amount điểm!'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      _amountController.clear();
      setState(() {
        _selectedAmount = 0;
        _selectedPaymentMethod = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nạp điểm thất bại. Vui lòng thử lại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showPaymentConfirmationDialog(int amount) async {
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
    );

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedMethod['name'] as String,
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
            const Text(
              'Bạn có chắc chắn muốn nạp điểm với phương thức thanh toán này không?',
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
