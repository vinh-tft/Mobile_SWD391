import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _streetController = TextEditingController();
  final _wardController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  bool _marketingConsent = false;
  String? _gender;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
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
          'Đăng ký tài khoản',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tiêu đề
                _buildHeader(),
                
                const SizedBox(height: 32),
                
                // Form đăng ký
                _buildRegisterForm(),
                
                const SizedBox(height: 16),
                
                // Điều khoản
                _buildTermsCheckbox(),
                
                const SizedBox(height: 24),
                
                // Nút đăng ký
                _buildRegisterButton(),
                
                const SizedBox(height: 24),
                
                // Đăng nhập
                _buildLoginSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Tạo tài khoản mới',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Đăng ký để bán quần áo lấy điểm và mua sắm bền vững',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Username
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Tên người dùng',
            hintText: 'Nhập username',
            prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF22C55E)),
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
              return 'Vui lòng nhập username';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // First name
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'Tên',
            hintText: 'Nhập tên',
            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF22C55E)),
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
              return 'Vui lòng nhập tên';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Last name
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên đệm',
            hintText: 'Nhập họ và tên đệm',
            prefixIcon: const Icon(Icons.perm_identity, color: Color(0xFF22C55E)),
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
        ),

        // Họ tên
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên',
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
            if (value.length < 2) {
              return 'Họ tên phải có ít nhất 2 ký tự';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),

        // Phone
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            hintText: 'Nhập số điện thoại',
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
        ),

        const SizedBox(height: 16),

        // Date of birth
        TextFormField(
          controller: _dobController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Ngày sinh',
            hintText: 'Chọn ngày sinh',
            prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF22C55E)),
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
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(now.year - 18, now.month, now.day),
              firstDate: DateTime(1900),
              lastDate: now,
            );
            if (picked != null) {
              _dobController.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            }
          },
        ),

        const SizedBox(height: 16),

        // Gender
        DropdownButtonFormField<String>(
          value: _gender,
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Nam')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
            DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
          ],
          decoration: InputDecoration(
            labelText: 'Giới tính',
            prefixIcon: const Icon(Icons.wc, color: Color(0xFF22C55E)),
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
          onChanged: (v) => setState(() => _gender = v),
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

        const SizedBox(height: 8),
        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Column(
      children: [
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
            const Expanded(
              child: Text(
                'Tôi đồng ý với Điều khoản sử dụng',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _agreeToPrivacy,
              onChanged: (value) {
                setState(() {
                  _agreeToPrivacy = value ?? false;
                });
              },
              activeColor: const Color(0xFF22C55E),
            ),
            const Expanded(
              child: Text(
                'Tôi đồng ý với Chính sách bảo mật',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _marketingConsent,
              onChanged: (value) {
                setState(() {
                  _marketingConsent = value ?? false;
                });
              },
              activeColor: const Color(0xFF22C55E),
            ),
            const Expanded(
              child: Text(
                'Tôi đồng ý nhận thông tin khuyến mãi',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || !_agreeToTerms) ? null : _handleRegister,
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
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Đăng ký',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Đã có tài khoản? ',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const Text(
            'Đăng nhập ngay',
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      _errorMessage = null;
    });

    // Thực hiện đăng ký đầy đủ
    final name = _nameController.text.trim();
    final parts = name.split(RegExp(r"\s+"));
    final first = _firstNameController.text.isNotEmpty ? _firstNameController.text : (parts.isNotEmpty ? parts.first : '');
    final last = _lastNameController.text.isNotEmpty ? _lastNameController.text : (parts.length > 1 ? parts.sublist(1).join(' ') : '');
    final username = _usernameController.text.isNotEmpty ? _usernameController.text : _emailController.text.split('@').first;

    bool success = false;
    try {
      success = await authService.registerFull(
        email: _emailController.text,
        password: _passwordController.text,
        username: username,
        firstName: first,
        lastName: last,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : '0000000000',
        dateOfBirth: _dobController.text.isNotEmpty ? _dobController.text : null,
        gender: _gender,
        streetAddress: _streetController.text.isNotEmpty ? _streetController.text : null,
        ward: _wardController.text.isNotEmpty ? _wardController.text : null,
        district: _districtController.text.isNotEmpty ? _districtController.text : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        province: _provinceController.text.isNotEmpty ? _provinceController.text : null,
        postalCode: _postalCodeController.text.isNotEmpty ? _postalCodeController.text : null,
        acceptTerms: _agreeToTerms,
        acceptPrivacy: _agreeToPrivacy,
        marketingConsent: _marketingConsent,
      );
    } catch (e) {
      success = false;
      String msg = e.toString();
      if (e is ApiException) {
        msg = e.body;
      }
      // Normalize common validation/error patterns
      final prefixRegex = RegExp(r'^(registration failed:|validation failed:|error:)\s*', caseSensitive: false);
      msg = msg.replaceAll(prefixRegex, '').trimLeft();
      // If backend returns multiple messages joined by |, keep as-is for clarity
      setState(() {
        _errorMessage = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return; // tránh hiển thị snackbar lỗi chung phía dưới
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _errorMessage = null;
      });
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Vui lòng đăng nhập'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );

      // Chuyển về trang đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }
}
