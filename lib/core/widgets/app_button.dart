import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppButtonType { primary, secondary, outline, danger, ghost }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? child;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _height,
      child: _buildButton(),
    );
  }

  double get _height {
    return switch (size) {
      AppButtonSize.small => 40,
      AppButtonSize.medium => 52,
      AppButtonSize.large => 58,
    };
  }

  double get _fontSize {
    return switch (size) {
      AppButtonSize.small => 13,
      AppButtonSize.medium => 15,
      AppButtonSize.large => 16,
    };
  }

  Widget _buildButton() {
    if (type == AppButtonType.outline) return _outlinedButton();
    if (type == AppButtonType.ghost) return _textButton();
    return _elevatedButton();
  }

  Color get _backgroundColor {
    if (onPressed == null) return AppColors.border;
    return switch (type) {
      AppButtonType.primary => AppColors.primary,
      AppButtonType.secondary => AppColors.secondary,
      AppButtonType.danger => AppColors.danger,
      _ => AppColors.primary,
    };
  }

  Color get _foregroundColor {
    if (onPressed == null) return AppColors.textHint;
    return switch (type) {
      AppButtonType.secondary => AppColors.textOnSecondary,
      _ => AppColors.textOnPrimary,
    };
  }

  Widget get _content {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AppButtonType.outline ? AppColors.primary : Colors.white,
          ),
        ),
      );
    }
    if (child != null) return child!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: _fontSize + 2),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(suffixIcon, size: _fontSize + 2),
        ],
      ],
    );
  }

  Widget _elevatedButton() {
    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed != null && type == AppButtonType.primary
            ? AppColors.primaryGradient
            : null,
        color: onPressed == null || type != AppButtonType.primary
            ? _backgroundColor
            : null,
        borderRadius: radius,
        boxShadow: onPressed != null && type == AppButtonType.primary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .24),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: _foregroundColor,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: _content,
      ),
    );
  }

  Widget _outlinedButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: type == AppButtonType.danger
            ? AppColors.danger
            : AppColors.primary,
        side: BorderSide(
          color: type == AppButtonType.danger
              ? AppColors.danger
              : AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: EdgeInsets.zero,
      ),
      child: _content,
    );
  }

  Widget _textButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: EdgeInsets.zero,
      ),
      child: _content,
    );
  }
}
