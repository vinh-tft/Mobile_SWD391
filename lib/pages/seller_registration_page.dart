import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class SellerRegistrationPage extends StatefulWidget {
  const SellerRegistrationPage({super.key});

  @override
  State<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends State<SellerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String _selectedCategory = 'Thời trang';
  int _currentStep = 0;

  final List<String> _categories = [
    'Thời trang',
    'Phụ kiện',
    'Giày dép',
    'Túi xách',
    'Đồ vintage',
    'Khác'
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          'Đăng ký bán hàng',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_currentStep == 0) _buildStep1(),
                      if (_currentStep == 1) _buildStep2(),
                      if (_currentStep == 2) _buildStep3(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildProgressStep(0, 'Thông tin cơ bản'),
          ),
          Expanded(
            child: _buildProgressStep(1, 'Thông tin cửa hàng'),
          ),
          Expanded(
            child: _buildProgressStep(2, 'Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title) {
    final isActive = step <= _currentStep;
    final isCompleted = step < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vui lòng cung cấp thông tin cá nhân của bạn',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 32),
        
        // Họ tên chủ cửa hàng
        TextFormField(
          controller: _ownerNameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên chủ cửa hàng',
            hintText: 'Nhập họ tên của bạn',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF22C55E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập họ tên';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Nhập email của bạn',
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF22C55E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Số điện thoại
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            hintText: 'Nhập số điện thoại của bạn',
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF22C55E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
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
        
        const SizedBox(height: 16),
        
        // Mật khẩu
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Nhập mật khẩu của bạn',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF22C55E)),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Xác nhận mật khẩu
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF22C55E)),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF6B7280),
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận mật khẩu';
            }
            if (value != _passwordController.text) {
              return 'Mật khẩu không khớp';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cửa hàng',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cung cấp thông tin về cửa hàng của bạn',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 32),
        
        // Tên cửa hàng
        TextFormField(
          controller: _storeNameController,
          decoration: InputDecoration(
            labelText: 'Tên cửa hàng',
            hintText: 'Nhập tên cửa hàng của bạn',
            prefixIcon: const Icon(Icons.store, color: Color(0xFF22C55E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập tên cửa hàng';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Danh mục
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Danh mục sản phẩm',
            prefixIcon: const Icon(Icons.category, color: Color(0xFF22C55E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Địa chỉ
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Địa chỉ cửa hàng',
            hintText: 'Nhập địa chỉ cửa hàng của bạn',
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF22C55E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập địa chỉ cửa hàng';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xác nhận thông tin',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vui lòng kiểm tra lại thông tin trước khi đăng ký',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 32),
        
        // Thông tin cá nhân
        _buildInfoCard('Thông tin cá nhân', [
          _buildInfoRow('Họ tên', _ownerNameController.text),
          _buildInfoRow('Email', _emailController.text),
          _buildInfoRow('Số điện thoại', _phoneController.text),
        ]),
        
        const SizedBox(height: 16),
        
        // Thông tin cửa hàng
        _buildInfoCard('Thông tin cửa hàng', [
          _buildInfoRow('Tên cửa hàng', _storeNameController.text),
          _buildInfoRow('Danh mục', _selectedCategory),
          _buildInfoRow('Địa chỉ', _addressController.text),
        ]),
        
        const SizedBox(height: 24),
        
        // Điều khoản
        Row(
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _agreeToTerms = !_agreeToTerms;
                  });
                },
                child: const Text(
                  'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của nền tảng bán hàng',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF22C55E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 2 ? 'Đăng ký' : 'Tiếp tục',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (_currentStep < 2) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep++;
        });
      }
    } else {
      await _handleRegister();
    }
  }

  Future<void> _handleRegister() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản sử dụng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    // Thực hiện đăng ký bán hàng
    final success = await authService.registerSeller(
      ownerName: _ownerNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
      storeName: _storeNameController.text,
      storeCategory: _selectedCategory,
      storeAddress: _addressController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký bán hàng thành công! Vui lòng đăng nhập'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );

      // Chuyển về trang đăng nhập
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      // Hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký bán hàng thất bại. Vui lòng thử lại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
