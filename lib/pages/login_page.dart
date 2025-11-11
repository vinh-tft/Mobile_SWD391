import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register_page.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/auth_theme.dart';
import '../widgets/google_signin_button.dart';

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
  bool _showResendModal = false;
  bool _resendLoading = false;
  String? _resendSuccess;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _buildBackdropCircle(
                size: 220,
                color: AuthTheme.primary.withOpacity(0.15),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildBackdropCircle(
                size: 260,
                color: AuthTheme.primaryDark.withOpacity(0.12),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildAuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildLoginForm(),
                            const SizedBox(height: 12),
                            _buildForgotPassword(),
                            const SizedBox(height: 24),
                            _buildPrimaryButton(
                              label: 'Đăng nhập',
                              onPressed: _handleLogin,
                              loading: _isLoading,
                            ),
                            const SizedBox(height: 24),
                            _buildDividerLabel('Hoặc tiếp tục với'),
                            const SizedBox(height: 20),
                            const GoogleSignInButton(),
                            const SizedBox(height: 28),
                            _buildRegisterSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showResendModal) _buildVerificationModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard({required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: AuthTheme.cardPadding,
      decoration: AuthTheme.cardDecoration(),
      child: child,
    );
  }

  Widget _buildBackdropCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    double height = 56,
  }) {
    final bool isDisabled = onPressed == null || loading;
    final borderRadius = BorderRadius.circular(16);
    final decoration = isDisabled
        ? BoxDecoration(
            color: AuthTheme.primary.withOpacity(0.5),
            borderRadius: borderRadius,
          )
        : BoxDecoration(
            gradient: AuthTheme.primaryGradient,
            borderRadius: borderRadius,
          );

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: Ink(
          decoration: decoration,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDividerLabel(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AuthTheme.border,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AuthTheme.neutral,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AuthTheme.border,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(24),
                decoration: AuthTheme.cardDecoration(borderRadius: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AuthTheme.accent.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.mail_outline,
                            color: AuthTheme.primaryDark,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Xác thực email của bạn',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AuthTheme.neutralStrong,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email của bạn chưa được xác thực. Chúng tôi đã gửi liên kết xác thực tới hộp thư của bạn.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AuthTheme.neutral,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AuthTheme.destructive.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AuthTheme.destructive,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_resendSuccess != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AuthTheme.accent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AuthTheme.primary.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AuthTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child:                               Text(
                                _resendSuccess!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AuthTheme.primaryDark,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Text(
                          'Chưa nhận được email? Nhấn gửi lại để nhận liên kết xác thực cho: ${_emailController.text}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildPrimaryButton(
                        label: _resendCooldown > 0
                            ? 'Đợi ${_resendCooldown}s để gửi lại'
                            : 'Gửi lại email xác thực',
                        onPressed: (_resendLoading || _resendCooldown > 0)
                            ? null
                            : _handleResendVerification,
                        loading: _resendLoading,
                        height: 48,
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _resendLoading ? null : _closeModal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AuthTheme.neutral,
                          side: BorderSide(color: AuthTheme.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Đóng'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sau khi xác thực thành công, vui lòng thử đăng nhập lại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AuthTheme.neutral,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: AuthTheme.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2054D28F),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.recycling,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Chào mừng trở lại!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AuthTheme.neutralStrong,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Đăng nhập để tiếp tục hành trình thời trang bền vững cùng Green Loop',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AuthTheme.neutral,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: AuthTheme.inputDecoration(
            label: 'Email',
            hint: 'Nhập email của bạn',
            leading: Icon(Icons.email_outlined, color: AuthTheme.primary),
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
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: AuthTheme.inputDecoration(
            label: 'Mật khẩu',
            hint: 'Nhập mật khẩu của bạn',
            leading: Icon(Icons.lock_outline, color: AuthTheme.primary),
            trailing: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AuthTheme.neutral,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
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
        const SizedBox(height: 10),
        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuthTheme.destructive.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AuthTheme.destructive,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tính năng quên mật khẩu sẽ được thêm sau'),
              backgroundColor: AuthTheme.primary,
            ),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: AuthTheme.primary,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.help_outline, size: 18),
            SizedBox(width: 6),
            Text('Quên mật khẩu?'),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Chưa có tài khoản?',
          textAlign: TextAlign.center,
          style: AuthTheme.subtitle(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AuthTheme.primary,
              side: BorderSide(color: AuthTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Tạo tài khoản Green Loop'),
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
      _showResendModal = false;
      _resendSuccess = null;
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

      // Check if error is about unverified email
      if (msg.toLowerCase().contains('verify your email') ||
          msg.toLowerCase().contains('email verification') ||
          msg.toLowerCase().contains('not verified')) {
        setState(() {
          _errorMessage = msg;
          _showResendModal = true;
        });
      } else {
        setState(() {
          _errorMessage = msg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AuthTheme.destructive),
        );
      }

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
          backgroundColor: AuthTheme.primary,
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
          backgroundColor: AuthTheme.destructive,
        ),
      );
    }
  }

  void _handleResendVerification() async {
    if (_resendCooldown > 0) {
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
      });
      return;
    }

    setState(() {
      _resendLoading = true;
      _errorMessage = null;
      _resendSuccess = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.resendVerification(email);

      if (success) {
        setState(() {
          _resendSuccess =
              'Email xác thực đã được gửi! Vui lòng kiểm tra hộp thư của bạn.';
          _resendCooldown = 60;
        });

        // Start countdown
        Future.doWhile(() async {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() {
              if (_resendCooldown > 0) {
                _resendCooldown--;
              }
            });
            return _resendCooldown > 0;
          }
          return false;
        });
      }
    } catch (e) {
      String msg = e.toString();
      if (e is ApiException) {
        msg = e.body;
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      setState(() {
        _resendLoading = false;
      });
    }
  }

  void _closeModal() {
    setState(() {
      _showResendModal = false;
      _resendSuccess = null;
      _errorMessage = null;
    });
  }
}
