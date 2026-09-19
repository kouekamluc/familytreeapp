import 'package:flutter/material.dart';
import '../config/royal_theme.dart';

class RoyalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? width;
  final double? height;

  const RoyalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.isSelected = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? RoyalTheme.cardDark : RoyalTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? RoyalTheme.brightGold
                  : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? RoyalTheme.brightGold.withOpacity(0.25)
                    : (isDark ? Colors.black38 : Colors.black12),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
