import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/session/app_session.dart';

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
        SnackBar(content: Text(context.l10n.serverSetupIsIncomplete)),
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
      AppSession.setAuthenticatedUser(
        id: profile.id,
        name: profile.name,
        role: profile.role.name,
        email: profile.email,
      );
      await AppSession.syncRemoteState();
      if (mounted) context.go('/admin/dashboard');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
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
                    context.l10n.adminPortal,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    context.l10n.appManagementSystem(AppBrand.name),
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
                          label: context.l10n.adminEmail,
                          prefixIcon: Icons.email,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? MessageCode.enterAnAdminEmail
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passwordController,
                          label: context.l10n.password,
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          validator: (value) => value == null || value.isEmpty
                              ? MessageCode.enterYourPassword
                              : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: context.l10n.loginAsAdmin,
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
                      context.l10n.backToUserLogin,
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
