import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A8A); // Deep Blue
  static const Color primaryDark = Color(0xFF172554);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFFF1F5F9); // Light Slate
  static const Color secondaryDark = Color(0xFF94A3B8);
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class AppStyles {
  static const double borderRadius = 16.0;
  static const double buttonHeight = 56.0;
  static const EdgeInsets screenPadding = EdgeInsets.all(20.0);

  static final BorderRadius commonBorderRadius = BorderRadius.circular(borderRadius);

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBgColor = widget.backgroundColor ?? AppColors.primary;
    final Color effectiveFgColor = widget.foregroundColor ?? Colors.white;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: SizedBox(
          width: double.infinity,
          height: AppStyles.buttonHeight,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPressed ? AppColors.primaryDark : effectiveBgColor,
              foregroundColor: effectiveFgColor,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: _isPressed ? 1 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.commonBorderRadius,
              ),
              shadowColor: AppColors.primary.withAlpha((0.3 * 255).round()),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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

