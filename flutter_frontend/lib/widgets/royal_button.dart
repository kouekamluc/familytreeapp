import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';

enum RoyalButtonVariant { gold, outline, ghost, emerald, danger }

class RoyalButton extends StatefulWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final RoyalButtonVariant variant;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final bool isLoading;

  const RoyalButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = RoyalButtonVariant.gold,
    this.width,
    this.height = 48,
    this.padding,
    this.fontSize = 14,
    this.isLoading = false,
  });

  @override
  State<RoyalButton> createState() => _RoyalButtonState();
}

class _RoyalButtonState extends State<RoyalButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Decoration decoration;
    Color textColor;

    switch (widget.variant) {
      case RoyalButtonVariant.gold:
        textColor = Colors.black;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? const Color(0xFFFFF0B8) : const Color(0xFFFFDE7A).withValues(alpha: 0.75),
            width: 1.2,
          ),
          gradient: LinearGradient(
            colors: _isHovered
                ? [const Color(0xFFD4AF37), const Color(0xFFF5D76E), const Color(0xFFE5C16C)]
                : [const Color(0xFFB8860B), const Color(0xFFD4AF37), const Color(0xFFC5A059)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: _isHovered ? 0.55 : 0.32),
              blurRadius: _isHovered ? 24 : 14,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        );
        break;

      case RoyalButtonVariant.outline:
        textColor = isDark ? RoyalTheme.lightGold : RoyalTheme.darkGold;
        decoration = BoxDecoration(
          color: _isHovered
              ? (isDark ? const Color(0xFF222532) : const Color(0xFFF7F2E7))
              : (isDark ? const Color(0xFF161822) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? RoyalTheme.brightGold : RoyalTheme.primaryGold.withValues(alpha: 0.7),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        );
        break;

      case RoyalButtonVariant.ghost:
        textColor = isDark ? Colors.white : Colors.black87;
        decoration = BoxDecoration(
          color: _isHovered
              ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        );
        break;

      case RoyalButtonVariant.emerald:
        textColor = Colors.white;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isHovered
                ? [const Color(0xFF059669), const Color(0xFF10B981)]
                : [const Color(0xFF047857), const Color(0xFF059669)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        );
        break;

      case RoyalButtonVariant.danger:
        textColor = Colors.white;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _isHovered ? const Color(0xFFDC2626) : const Color(0xFFB91C1C),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
        break;
    }

    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: isDisabled
            ? null
            : (_) {
                HapticFeedback.lightImpact();
                setState(() => _isPressed = true);
              },
        onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.025 : 1.0),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 22),
            decoration: decoration,
            child: Row(
              mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
