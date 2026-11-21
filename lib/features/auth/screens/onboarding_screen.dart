import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/navigation/launch_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  Future<void> _finish() async {
    await LaunchPreferences.markOnboardingSeen();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Light page: dark status-bar icons (the blue splash before it used light).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() => isLastPage = index == 2);
              },
              children: [
                _buildSlide(
                  icon: Icons.explore_rounded,
                  title: MessageCode.discoverBustos,
                  description: MessageCode
                      .exploreTheHeritageNatureAndBeautyOfBustosBulacanWithEase,
                ),
                _buildSlide(
                  icon: Icons.electric_rickshaw,
                  title: MessageCode.bookATricycle,
                  description: MessageCode
                      .getAroundQuicklyAndSafelyByBookingLocalTricycleDriversInSeconds,
                ),
                _buildSlide(
                  icon: Icons.route,
                  title: MessageCode.yourJourneyYourWay,
                  description: MessageCode
                      .buildYourItineraryAndEnjoyAPersonalizedTourExperience,
                ),
              ],
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    context.l10n.skip,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              alignment: const Alignment(0, 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: Colors.black12,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  isLastPage
                      ? SizedBox(
                          width: 140,
                          child: AppButton(
                            label: context.l10n.getStarted,
                            onPressed: _finish,
                          ),
                        )
                      : IconButton(
                          tooltip: context.l10n.next,
                          onPressed: () => _controller.nextPage(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          ),
                          icon: const Icon(Icons.arrow_forward_ios),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required String title,
    required String description,
  }) {
    // Centred vertically, with room at the bottom for the page controls.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 72, 32, 120),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 192).clamp(0, double.infinity),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .7, end: 1),
                duration: Motion.of(context, const Duration(milliseconds: 600)),
                curve: Motion.pop,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: .07),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 64, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 44),
              FadeSlideIn(
                delay: Motion.short,
                child: Text(
                  context.message(title),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: Motion.short + Motion.stagger,
                child: Text(
                  context.message(description),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
