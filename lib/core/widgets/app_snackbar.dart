import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackType { success, error, warning, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackType type = SnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = switch (type) {
      SnackType.success => AppColors.success,
      SnackType.error => AppColors.danger,
      SnackType.warning => AppColors.warning,
      SnackType.info => AppColors.primary,
    };

    final icon = switch (type) {
      SnackType.success => Icons.check_circle_rounded,
      SnackType.error => Icons.error_rounded,
      SnackType.warning => Icons.warning_rounded,
      SnackType.info => Icons.info_rounded,
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
}

class AppDialog {
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppColors.danger : AppColors.primary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
