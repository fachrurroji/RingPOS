import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username and password');
      return;
    }

    setState(() => _error = null);
    
    final success = await ref.read(authProvider.notifier).login(username, password);
    
    if (success && mounted) {
      final authState = ref.read(authProvider);
      if (authState.isSuperadmin) {
        Navigator.pushReplacementNamed(context, '/superadmin');
      } else {
        Navigator.pushReplacementNamed(context, '/admin');
      }
    } else if (mounted) {
      setState(() => _error = ref.read(authProvider).error ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.point_of_sale, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('RingPOS', style: TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Cloud-Based Point of Sales', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 48),
              
              // Login Card
              Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome Back', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Enter your credentials to continue', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 32),
                    
                    // Error Message
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    
                    // Username
                    const Text('Username', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('Enter your username', Icons.person_outline),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 20),
                    
                    // Password
                    const Text('Password', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('Enter your password', Icons.lock_outline),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 12),
                    
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.accentBlue)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Demo Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('Demo Credentials', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuickLogin('superadmin', 'super123', 'Superadmin', Colors.red),
                        const SizedBox(width: 8),
                        _buildQuickLogin('admin', 'admin123', 'Retail', Colors.blue),
                        const SizedBox(width: 8),
                        _buildQuickLogin('fnbadmin', 'fnb123', 'F&B', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Text('Powered by Your ISP Provider', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.cardDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.accentBlue)),
      prefixIcon: Icon(icon, color: AppTheme.textSecondary),
    );
  }

  Widget _buildQuickLogin(String username, String password, String label, Color color) {
    return TextButton(
      onPressed: () {
        _usernameController.text = username;
        _passwordController.text = password;
        _login();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

