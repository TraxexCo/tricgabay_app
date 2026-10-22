import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/app_translations.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _isLoading = false;
  String _role = 'tourist';

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Server setup is incomplete. Add the Supabase build configuration before signing in.',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final role = _role == 'driver' ? AppRole.driver : AppRole.tourist;
      final profile = await AuthService.signIn(
        email: _emailCtrl.text,
        password: _pwdCtrl.text,
        expectedRole: role,
      );
      PrototypeSession.setAuthenticatedUser(
        id: profile.id,
        name: profile.name,
        role: profile.role.name,
        email: profile.email,
        plateNumber: profile.plateNumber,
      );
      await PrototypeSession.syncRemoteState();
      if (!mounted) return;
      context.go(
        profile.role == AppRole.driver ? '/driver/home' : '/tourist/home',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PrototypeSession.isFilipino,
      builder: (context, isFilipino, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const AppLogo(size: 58),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRIC-GABAY',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                context.tr(
                                  'Your local journey starts here',
                                  'Ang iyong lokal na paglalakbay ay nagsisimula dito',
                                ),
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    context.tr('Welcome back', 'Maligayang pagbabalik'),
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'Choose your workspace, then sign in to continue.',
                      'Piliin ang iyong workspace, pagkatapos ay mag-sign in upang magpatuloy.',
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFF5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _roleOption(
                          'tourist',
                          Icons.explore_outlined,
                          context.tr('Explore', 'Tuklasin'),
                        ),
                        _roleOption(
                          'driver',
                          Icons.electric_rickshaw_outlined,
                          context.tr('Drive', 'Magmaneho'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  AppTextField(
                    controller: _emailCtrl,
                    label: context.tr('Email Address', 'Email Address'),
                    hint: context.tr(
                      'Enter your email',
                      'Ilagay ang iyong email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _pwdCtrl,
                    label: context.tr('Password', 'Password'),
                    hint: context.tr(
                      'Enter your password',
                      'Ilagay ang iyong password',
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password is required' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(
                        context.tr(
                          'Forgot Password?',
                          'Nakalimutan ang Password?',
                        ),
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _role == 'tourist'
                        ? context.tr(
                            'Enter tourist app',
                            'Pumasok sa tourist app',
                          )
                        : context.tr(
                            'Enter driver app',
                            'Pumasok sa driver app',
                          ),
                    prefixIcon: _role == 'tourist'
                        ? Icons.explore
                        : Icons.electric_rickshaw,
                    isLoading: _isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr(
                          "Don't have an account?",
                          "Wala pang account?",
                        ),
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register/role'),
                        child: Text(
                          context.tr('Sign Up', 'Mag-sign Up'),
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/admin/login'),
                    child: Text(
                      context.tr(
                        'Manage Tric-Gabay? Open the admin portal',
                        'Pamahalaan ang Tric-Gabay? Buksan ang admin portal',
                      ),
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
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

  Widget _roleOption(String value, IconData icon, String label) {
    final selected = _role == value;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: '$label mode',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _role = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x160D1B2A),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
