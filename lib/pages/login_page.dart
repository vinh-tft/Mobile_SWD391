import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register_page.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo và tiêu đề
                _buildHeader(),
                
                const SizedBox(height: 48),
                
                // Form đăng nhập
                _buildLoginForm(),
                
                const SizedBox(height: 24),
                
                // Nút đăng nhập
                _buildLoginButton(),
                
                const SizedBox(height: 16),
                
                // Quên mật khẩu
                _buildForgotPassword(),
                
                const SizedBox(height: 32),
                
                // Đăng ký
                _buildRegisterSection(),
                
                const SizedBox(height: 24),
                
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
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.recycling,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        
        // Tiêu đề
        const Text(
          'Chào mừng trở lại!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Đăng nhập để bán quần áo lấy điểm hoặc quản lý cửa hàng',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
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

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tính năng quên mật khẩu sẽ được thêm sau'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        },
        child: const Text(
          'Quên mật khẩu?',
          style: TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản? ',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
          child: const Text(
            'Đăng ký ngay',
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


  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = false;
    try {
      success = await authService.login(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      String msg = e.toString();
      if (e is ApiException) {
        msg = e.body;
      }
      // UI-level normalization as a safeguard in case backend messages change
      final prefixRegex = RegExp(r'^(login failed:\s*)+', caseSensitive: false);
      msg = msg.replaceFirst(prefixRegex, '').trimLeft();
      if (RegExp('bad credentials', caseSensitive: false).hasMatch(msg)) {
        msg = 'Email hoặc mật khẩu không đúng';
      }
      setState(() {
        _errorMessage = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _errorMessage = null;
      });
      
      // Lấy thông tin user để check role
      final currentUser = authService.currentUser;
      String roleMessage = 'Đăng nhập thành công!';
      
      if (currentUser != null) {
        if (currentUser.role == UserRole.staff) {
          roleMessage = 'Chào mừng nhân viên ${currentUser.name}!';
        } else {
          roleMessage = 'Chào mừng khách hàng ${currentUser.name}!';
        }
      }
      
      // Hiển thị thông báo thành công với role
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(roleMessage),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      
      // App sẽ tự động redirect sau khi login thành công
      // Không cần Navigator.pop() vì authentication guard sẽ handle
    } else {
      // Hiển thị thông báo lỗi
      final fallback = 'Email hoặc mật khẩu không đúng';
      setState(() {
        _errorMessage = _errorMessage ?? fallback;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? fallback),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
