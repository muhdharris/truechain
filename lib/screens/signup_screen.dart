// lib/screens/signup_screen.dart - Updated with simple authentication
import 'package:flutter/material.dart';
import '../services/simple_auth_service.dart';
import 'admin_login_screen.dart';
import 'customer_login_screen.dart';
import 'dashboard_screen.dart';
import 'dashboard_customer.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = SimpleAuthService();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _selectedRole = 'customer';
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      _showMessage('Please accept the terms and conditions', Colors.red);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
      );

      _showMessage('Account created successfully!', Colors.green);

      // Navigate based on role
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        if (_selectedRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerDashboardScreen()),
          );
        }
      }
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _selectedRole == 'admin'
                ? [Color(0xFF5B5CE6), Color(0xFF4338CA), Color(0xFF312E81)]
                : [Color(0xFF059669), Color(0xFF065f46), Color(0xFF064e3b)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 900;
              return isWide ? _buildWideLayout() : _buildMobileLayout();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(child: _buildBrandingSection()),
        Expanded(child: Center(child: _buildSignUpForm())),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildLogo(false),
          const SizedBox(height: 30),
          _buildSignUpForm(),
        ],
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(true),
          const SizedBox(height: 48),
          Text(
            _selectedRole == 'admin' ? 'Join as Admin' : 'Join as Customer',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedRole == 'admin'
                ? 'Get administrative access to manage the supply chain operations.'
                : 'Create your account to track products and shipments with transparency.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isLarge) {
    double size = isLarge ? 80 : 60;
    double fontSize = isLarge ? 42 : 32;
    IconData icon = _selectedRole == 'admin' ? Icons.business : Icons.eco;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white, Color(0xFFF0F0F0)]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: _selectedRole == 'admin' 
                ? const Color(0xFF5B5CE6) 
                : const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          'TrueChain',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedRole == 'admin' ? Icons.business : Icons.eco,
                  color: _selectedRole == 'admin' 
                      ? const Color(0xFF5B5CE6) 
                      : const Color(0xFF059669),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Join the supply chain transparency platform',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Role Selection
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'customer'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer'
                                  ? const Color(0xFF059669).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedRole == 'customer'
                                    ? const Color(0xFF059669)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'customer',
                                  groupValue: _selectedRole,
                                  onChanged: (value) => setState(() => _selectedRole = value!),
                                  activeColor: const Color(0xFF059669),
                                ),
                                const Icon(Icons.eco, size: 16),
                                const SizedBox(width: 8),
                                const Text('Customer'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'admin'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'admin'
                                  ? const Color(0xFF5B5CE6).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedRole == 'admin'
                                    ? const Color(0xFF5B5CE6)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'admin',
                                  groupValue: _selectedRole,
                                  onChanged: (value) => setState(() => _selectedRole = value!),
                                  activeColor: const Color(0xFF5B5CE6),
                                ),
                                const Icon(Icons.business, size: 16),
                                const SizedBox(width: 8),
                                const Text('Admin'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Switch to Login Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CustomerLoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFF059669), width: 1),
                      backgroundColor: const Color(0xFF059669).withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, color: const Color(0xFF059669), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Customer Login',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AdminLoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFF5B5CE6), width: 1),
                      backgroundColor: const Color(0xFF5B5CE6).withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business, color: const Color(0xFF5B5CE6), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Admin Login',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5B5CE6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name Field
            _buildTextField(
              _nameController,
              'Full Name',
              'Enter your full name',
              Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            _buildTextField(
              _emailController,
              'Email',
              'Enter your email address',
              Icons.mail_outline,
              validator: (value) {
                return SimpleAuthService.validateEmail(value ?? '');
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            _buildTextField(
              _passwordController,
              'Password',
              'Create a password',
              Icons.lock_outline,
              isPassword: true,
              isPasswordVisible: _isPasswordVisible,
              onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              validator: (value) {
                return SimpleAuthService.validatePassword(value ?? '');
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            _buildTextField(
              _confirmPasswordController,
              'Confirm Password',
              'Confirm your password',
              Icons.lock_outline,
              isPassword: true,
              isPasswordVisible: _isConfirmPasswordVisible,
              onTogglePassword: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Terms and Conditions
            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) => setState(() => _agreeToTerms = value!),
                  activeColor: _selectedRole == 'admin' 
                      ? const Color(0xFF5B5CE6) 
                      : const Color(0xFF059669),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
                    child: const Text(
                      'I agree to the Terms and Conditions and Privacy Policy',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sign Up Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _selectedRole == 'admin'
                      ? [Color(0xFF5B5CE6), Color(0xFF4338CA)]
                      : [Color(0xFF059669), Color(0xFF065f46)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Creating Account...',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      )
                    : Text(
                        _selectedRole == 'admin' 
                            ? 'Create Admin Account' 
                            : 'Create Customer Account',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Already have account
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? ", style: TextStyle(fontSize: 13)),
                TextButton(
                  onPressed: () {
                    if (_selectedRole == 'admin') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AdminLoginScreen()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CustomerLoginScreen()),
                      );
                    }
                  },
                  child: const Text('Sign In', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !(isPasswordVisible ?? false) : false,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible! ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorStyle: const TextStyle(fontSize: 12),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}