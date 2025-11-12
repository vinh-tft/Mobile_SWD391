import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/auth_theme.dart';

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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AuthTheme.neutralStrong),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Register Account',
          style: TextStyle(
            color: AuthTheme.neutralStrong,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              right: -90,
              child: _buildBackdropCircle(
                size: 260,
                color: AuthTheme.primary.withOpacity(0.15),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -100,
              child: _buildBackdropCircle(
                size: 300,
                color: AuthTheme.primaryDark.withOpacity(0.12),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildAuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildRegisterForm(),
                            const SizedBox(height: 20),
                            _buildTermsCheckbox(),
                            const SizedBox(height: 24),
                            _buildPrimaryButton(
                              label: 'Register',
                              onPressed: _agreeToTerms ? _handleRegister : null,
                              loading: _isLoading,
                            ),
                            const SizedBox(height: 24),
                            _buildLoginSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
      decoration: AuthTheme.cardDecoration(borderRadius: 26),
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
            color: color.withOpacity(0.3),
            blurRadius: 60,
            spreadRadius: 8,
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AuthTheme.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Start your journey with Green Loop',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthTheme.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Create New Account',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AuthTheme.neutralStrong,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Register to sell clothes for points and shop sustainably',
          style: TextStyle(
            fontSize: 15,
            color: AuthTheme.neutral,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: AuthTheme.inputDecoration(
            label: 'Username',
            hint: 'Enter username',
            leading:
                Icon(Icons.alternate_email, color: AuthTheme.primary),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter username';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstNameController,
          decoration: AuthTheme.inputDecoration(
            label: 'First Name',
            hint: 'Enter first name',
            leading: Icon(Icons.badge_outlined, color: AuthTheme.primary),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: AuthTheme.inputDecoration(
            label: 'Last Name',
            hint: 'Enter last name',
            leading: Icon(Icons.perm_identity, color: AuthTheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: AuthTheme.inputDecoration(
            label: 'Full Name',
            hint: 'Enter your full name',
            leading: Icon(Icons.person_outline, color: AuthTheme.primary),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter full name';
            }
            if (value.length < 2) {
              return 'Full name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: AuthTheme.inputDecoration(
            label: 'Phone Number',
            hint: 'Enter phone number',
            leading: Icon(Icons.phone_outlined, color: AuthTheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          decoration: AuthTheme.inputDecoration(
            label: 'Date of Birth',
            hint: 'Select date of birth',
            leading: Icon(Icons.cake_outlined, color: AuthTheme.primary),
            trailing: Icon(Icons.calendar_today_outlined,
                color: AuthTheme.neutral),
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
              _dobController.text =
                  '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _gender,
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          decoration: AuthTheme.inputDecoration(
            label: 'Gender',
            leading: Icon(Icons.wc, color: AuthTheme.primary),
          ),
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: AuthTheme.inputDecoration(
            label: 'Email',
            hint: 'Enter your email',
            leading: Icon(Icons.email_outlined, color: AuthTheme.primary),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Invalid email format';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: AuthTheme.inputDecoration(
            label: 'Password',
            hint: 'Enter your password',
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
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: AuthTheme.inputDecoration(
            label: 'Confirm Password',
            hint: 'Re-enter password',
            leading: Icon(Icons.lock_outline, color: AuthTheme.primary),
            trailing: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AuthTheme.neutral,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
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

  Widget _buildTermsCheckbox() {
    return Column(
      children: [
        _buildAgreementRow(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          label: 'I agree to the Terms of Service',
          required: true,
        ),
        _buildAgreementRow(
          value: _agreeToPrivacy,
          onChanged: (value) =>
              setState(() => _agreeToPrivacy = value ?? false),
          label: 'I agree to the Privacy Policy',
        ),
        _buildAgreementRow(
          value: _marketingConsent,
          onChanged: (value) =>
              setState(() => _marketingConsent = value ?? false),
          label: 'I agree to receive promotional information',
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Column(
      children: [
        Text(
          'Already have an account?',
          style: AuthTheme.subtitle(),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: AuthTheme.primary,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Login Now'),
        ),
      ],
    );
  }

  Widget _buildAgreementRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AuthTheme.primary,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AuthTheme.subtitle(),
                children: [
                  TextSpan(text: label),
                  if (required)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AuthTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the terms of service'),
          backgroundColor: AuthTheme.destructive,
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
    final first = _firstNameController.text.isNotEmpty
        ? _firstNameController.text
        : (parts.isNotEmpty ? parts.first : '');
    final last = _lastNameController.text.isNotEmpty
        ? _lastNameController.text
        : (parts.length > 1 ? parts.sublist(1).join(' ') : '');
    final username = _usernameController.text.isNotEmpty
        ? _usernameController.text
        : _emailController.text.split('@').first;

    bool success = false;
    try {
      success = await authService.registerFull(
        email: _emailController.text,
        password: _passwordController.text,
        username: username,
        firstName: first,
        lastName: last,
        phone: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : '0000000000',
        dateOfBirth:
            _dobController.text.isNotEmpty ? _dobController.text : null,
        gender: _gender,
        streetAddress:
            _streetController.text.isNotEmpty ? _streetController.text : null,
        ward: _wardController.text.isNotEmpty ? _wardController.text : null,
        district: _districtController.text.isNotEmpty
            ? _districtController.text
            : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        province: _provinceController.text.isNotEmpty
            ? _provinceController.text
            : null,
        postalCode: _postalCodeController.text.isNotEmpty
            ? _postalCodeController.text
            : null,
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
      final prefixRegex = RegExp(
          r'^(registration failed:|validation failed:|error:)\s*',
          caseSensitive: false);
      msg = msg.replaceAll(prefixRegex, '').trimLeft();
      // If backend returns multiple messages joined by |, keep as-is for clarity
      setState(() {
        _errorMessage = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AuthTheme.destructive),
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
        SnackBar(
          content: Text('Registration successful! Please login'),
          backgroundColor: AuthTheme.primary,
        ),
      );

      // Navigate to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }
}
