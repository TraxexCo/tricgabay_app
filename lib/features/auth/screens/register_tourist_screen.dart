import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/auth_service.dart';

class RegisterTouristScreen extends ConsumerStatefulWidget {
  const RegisterTouristScreen({super.key});

  @override
  ConsumerState<RegisterTouristScreen> createState() =>
      _RegisterTouristScreenState();
}

class _RegisterTouristScreenState extends ConsumerState<RegisterTouristScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _agreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate() || !_agreed) return;
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server setup is incomplete.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.registerTourist(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Confirm your email, then sign in.'),
        ),
      );
      context.go('/login');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Tourist Account',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'John Doe',
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || v.trim().length < 2
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'john@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: '+63 912 345 6789',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.replaceAll(RegExp(r'\D'), '').length < 10
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: 'Min. 8 characters',
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || v.length < 8
                    ? 'Password must be at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                hint: 'Retype password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms and Conditions',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Register',
                isLoading: _isLoading,
                onPressed: _agreed ? _register : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Login',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
