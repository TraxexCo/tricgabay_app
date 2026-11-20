import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed: () => context.go('/login'),
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
                          onPressed: () => context.go('/login'),
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
    );
  }

  Widget _buildSlide({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 120, color: AppColors.primary),
            const SizedBox(height: 48),
            Text(
              context.message(title),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              context.message(description),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
