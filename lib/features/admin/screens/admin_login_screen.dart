import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/prototype/prototype_session.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server setup is incomplete.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final profile = await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        expectedRole: AppRole.admin,
      );
      PrototypeSession.setAuthenticatedUser(
        id: profile.id,
        name: profile.name,
        role: profile.role.name,
        email: profile.email,
      );
      await PrototypeSession.syncRemoteState();
      if (mounted) context.go('/admin/dashboard');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark theme for admin
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 112, showShadow: true),
                  const SizedBox(height: 24),
                  Text(
                    'Admin Portal',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tric Gabay Management System',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _emailController,
                          label: 'Admin Email',
                          prefixIcon: Icons.email,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter an admin email'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter your password'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Login as Admin',
                            isLoading: _loading,
                            onPressed: _login,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Back to User Login',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
