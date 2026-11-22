import 'dart:async';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../l10n/record_labels.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../motion/motion.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogo({super.key, this.size = 56, this.showShadow = false});

  static const _asset = 'assets/images/tric_gabay_logo.png';

  /// The exact image this logo draws at [size], so callers can precache it
  /// and the logo never flashes blank while decoding.
  static ImageProvider provider(BuildContext context, double size) =>
      providerFor(MediaQuery.devicePixelRatioOf(context), size);

  static ImageProvider providerFor(double devicePixelRatio, double size) =>
      ResizeImage.resizeIfNeeded(
        null,
        (size * devicePixelRatio).ceil(),
        const AssetImage(_asset),
      );

  /// Decodes the launch-size logo before the first frame, so the hand-over
  /// from the phone's launch screen never shows an empty circle. Gives up
  /// quietly after two seconds.
  static Future<void> warmUp(double size) {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return Future.value();
    final done = Completer<void>();
    final stream = providerFor(
      views.first.devicePixelRatio,
      size,
    ).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        if (!done.isCompleted) done.complete();
      },
      onError: (_, _) {
        if (!done.isCompleted) done.complete();
      },
    );
    stream.addListener(listener);
    return done.future
        .timeout(const Duration(seconds: 2), onTimeout: () {})
        .whenComplete(() => stream.removeListener(listener));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: size * 0.045),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image(
        image: provider(context, size),
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    );
  }
}

class SafeAppImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SafeAppImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final imageWidth = width ?? constraints.maxWidth;
      final pixelWidth = imageWidth.isFinite && imageWidth > 0
          ? (imageWidth * MediaQuery.devicePixelRatioOf(context) / 64)
                    .ceil()
                    .clamp(1, 24) *
                64
          : null;
      return _image(context, pixelWidth);
    },
  );

  Widget _image(BuildContext context, int? pixelWidth) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE8EEF2),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: pixelWidth,
        placeholder: (context, url) => SizedBox(
          width: width,
          height: height,
          child: const ColoredBox(color: Color(0xFFE8EEF2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: const Color(0xFFE8EEF2),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return Image.asset(
      optimizedPhotoAsset(path),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: pixelWidth,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: const Color(0xFFE8EEF2),
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Keep older catalog rows and APKs compatible with the original asset paths.
String optimizedPhotoAsset(String path) =>
    path.startsWith('assets/images/') && path.endsWith('.jpg')
    ? 'assets/optimized_images/${path.split('/').last.replaceFirst('.jpg', '.webp')}'
    : path;

class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: context.message(message ?? MessageCode.loading),
      child: ExcludeSemantics(
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      context.message(message!),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The icon pops in and the text follows, so an empty list reads
              // as a deliberate state rather than a blank screen.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: Motion.of(context, Motion.long),
                curve: Motion.pop,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.message(title),
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  context.message(subtitle!),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onAction,
                  child: Text(context.message(actionLabel!)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final BookingStatus? bookingStatus;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.bookingStatus,
  });

  factory StatusBadge.bookingStatus(BookingStatus status) {
    final (color, text) = switch (status) {
      BookingStatus.scheduled => (AppColors.infoLight, AppColors.info),
      BookingStatus.pending => (AppColors.warningLight, AppColors.warning),
      BookingStatus.accepted => (AppColors.successLight, AppColors.success),
      BookingStatus.replacementPending => (
        AppColors.dangerLight,
        AppColors.danger,
      ),
      BookingStatus.ongoing => (AppColors.infoLight, AppColors.info),
      BookingStatus.completed => (
        const Color(0xFFEDE7F6),
        const Color(0xFF8E44AD),
      ),
      BookingStatus.cancelled => (AppColors.dangerLight, AppColors.danger),
      _ => (AppColors.surfaceVariant, AppColors.textSecondary),
    };
    return StatusBadge(
      label: MessageCode.unknown,
      color: color,
      textColor: text,
      bookingStatus: status,
    );
  }

  factory StatusBadge.driverStatus(String status) {
    final (color, text) = switch (status.toLowerCase()) {
      'online' => (AppColors.successLight, AppColors.success),
      'offline' => (AppColors.surfaceVariant, AppColors.textSecondary),
      'busy' => (AppColors.warningLight, AppColors.warning),
      _ => (AppColors.surfaceVariant, AppColors.textSecondary),
    };
    return StatusBadge(
      label: status.toUpperCase(),
      color: color,
      textColor: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel = bookingStatus == null
        ? context.message(label)
        : bookingStatusLabel(context, bookingStatus!);
    return Semantics(
      label: context.l10n.statusValue(displayLabel),
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayLabel,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102A43),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.border.withValues(alpha: .82),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppSnackbar {
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.danger);

  static void _show(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.message(message)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
