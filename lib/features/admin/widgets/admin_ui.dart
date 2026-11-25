import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/booking_model.dart';

/// Pieces shared by the admin screens so they look like one product.

/// Bookings that need an admin to check the money side.
bool needsPaymentReview(BookingModel b) =>
    b.trip.reviewRequired ||
    b.paymentStatus == PaymentStatus.disputed ||
    b.paymentStatus == PaymentStatus.failed ||
    b.paymentStatus == PaymentStatus.refundDue ||
    b.paymentStatus == PaymentStatus.refundProcessing ||
    b.paymentStatus == PaymentStatus.partiallyRefunded;

bool isOpenGcashDispute(BookingModel b) =>
    b.paymentMethod == PaymentMethod.gcashDirect &&
    b.paymentStatus == PaymentStatus.disputed;

/// Small red pill with a count. Hidden when [count] is zero.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.color = AppColors.danger});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.poppins(
          fontSize: 11,
          height: 1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Section heading used on admin screens.
class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// An empty state that still works inside a [RefreshIndicator]: the list can
/// be pulled to check again.
class ScrollableEmptyState extends StatelessWidget {
  const ScrollableEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: EmptyStateWidget(icon: icon, title: title, subtitle: subtitle),
        ),
      ],
    ),
  );
}

/// White rounded panel with a thin border, the basic admin surface.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderColor = AppColors.border,
    this.color = AppColors.surface,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding, margin;
  final Color borderColor, color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Rounded tinted square with an icon.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, this.color, {super.key, this.size = 42});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: Icon(icon, color: color, size: size * .52),
  );
}

/// Shows a short message with an icon at the bottom of the screen.
void showAdminToast(
  BuildContext context,
  String message, {
  bool error = false,
}) => error
    ? AppSnackbar.showError(context, message)
    : AppSnackbar.showSuccess(context, message);
