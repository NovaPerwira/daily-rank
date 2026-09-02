import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      username: _usernameCtrl.text.trim(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    const Text('⚔️', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    const Text(
                      'CREATE YOUR HERO',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Begin your legendary journey',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 32),

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
                ).animate().fadeIn(duration: 300.ms),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Username
                    TextFormField(
                      controller: _usernameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Hero Name',
                        hintText: 'Your username',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Hero name is required';
                        if (v.length < 3) return 'At least 3 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email
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

                    // Password
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
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

              const SizedBox(height: 32),

              // Register button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _register,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'BEGIN JOURNEY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already a hero? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
