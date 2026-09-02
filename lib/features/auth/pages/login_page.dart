import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGlow,
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('👑', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'LIFE RANK',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Continue your journey',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0, duration: 600.ms),

              const SizedBox(height: 48),

              // Error message
              if (auth.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email field
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'your@email.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) return 'Invalid email format';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

              const SizedBox(height: 32),

              // Login button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'START PLAYING',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 300.ms),

              const SizedBox(height: 24),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      'Create Hero',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

              const SizedBox(height: 40),

              // RPG decorative text
              Center(
                child: Text(
                  '⚔️  Level up your life  ⚔️',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
