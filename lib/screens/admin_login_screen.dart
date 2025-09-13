// lib/screens/admin_login_screen.dart - Updated with simple authentication
import 'package:flutter/material.dart';
import '../services/simple_auth_service.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import 'customer_login_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = SimpleAuthService();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    String? emailError = SimpleAuthService.validateEmail(_emailController.text.trim());
    if (emailError != null) {
      _showMessage(emailError, Colors.red);
      return;
    }

    String? passwordError = SimpleAuthService.validatePassword(_passwordController.text);
    if (passwordError != null) {
      _showMessage(passwordError, Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use simple admin login
      await _authService.adminLogin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      _showMessage('Admin login successful!', Colors.green);
      
      // Direct to admin dashboard
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
      
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _showDemoCredentials() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Demo Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Use these credentials to test admin login:'),
            const SizedBox(height: 16),
            _buildCredentialRow('Email:', 'admin@truechain.com'),
            _buildCredentialRow('Password:', 'admin123'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildCredentialRow('Email:', 'manager@truechain.com'),
            _buildCredentialRow('Password:', 'manager123'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              _emailController.text = 'admin@truechain.com';
              _passwordController.text = 'admin123';
              Navigator.pop(context);
            },
            child: const Text('Use Admin Credentials'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5B5CE6), Color(0xFF4338CA), Color(0xFF312E81)],
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
        Expanded(child: Center(child: _buildLoginForm())),
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
          _buildLoginForm(),
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
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your supply chain operations with blockchain technology.',
            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isLarge) {
    double size = isLarge ? 80 : 60;
    double fontSize = isLarge ? 42 : 32;
    
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
          child: Icon(Icons.business, size: size * 0.5, color: const Color(0xFF5B5CE6)),
        ),
        const SizedBox(width: 20),
        Text(
          'TrueChain Admin',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, color: const Color(0xFF5B5CE6), size: 24),
              const SizedBox(width: 8),
              const Text('Admin Sign In', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Access the supply chain dashboard', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          // Demo Credentials Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton(
              onPressed: _showDemoCredentials,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF059669), width: 1),
                backgroundColor: const Color(0xFF059669).withOpacity(0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF059669), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Show Demo Credentials',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Switch to Customer Login
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerLoginScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: Color(0xFF059669), width: 2),
                backgroundColor: const Color(0xFF059669).withOpacity(0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, color: const Color(0xFF059669), size: 18),
                  const SizedBox(width: 10),
                  const Text(
                    'Switch to Customer Login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Role Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF5B5CE6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5B5CE6).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: const Color(0xFF5B5CE6), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only admin accounts can access this portal',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF5B5CE6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Email Field
          _buildTextField(_emailController, 'Admin Email', 'Enter admin email', Icons.mail_outline),
          const SizedBox(height: 16),

          // Password Field
          _buildTextField(
            _passwordController,
            'Password',
            'Enter admin password',
            Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isPasswordVisible,
            onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 12),

          // Remember Me & Forgot Password
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) => setState(() => _rememberMe = value!),
                activeColor: const Color(0xFF5B5CE6),
              ),
              const Text('Remember me', style: TextStyle(fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: () => _showForgotPasswordDialog(), 
                child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Login Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF5B5CE6), Color(0xFF4338CA)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAdminLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('Verifying Admin Access...', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    )
                  : const Text('Sign In to Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),

          // Sign Up Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Need admin access? ", style: TextStyle(fontSize: 13)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen())),
                child: const Text('Request Account', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword ? !(isPasswordVisible ?? false) : false,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(isPasswordVisible! ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
                    onPressed: onTogglePassword,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetController = TextEditingController();
    if (_emailController.text.isNotEmpty) resetController.text = _emailController.text;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Admin Password'),
        content: TextField(
          controller: resetController,
          decoration: const InputDecoration(
            labelText: 'Admin Email Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.resetPassword(resetController.text.trim());
                Navigator.pop(context);
                _showMessage('Reset link sent!', Colors.green);
              } catch (e) {
                _showMessage(e.toString().replaceFirst('Exception: ', ''), Colors.red);
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}