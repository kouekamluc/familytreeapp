import 'package:flutter/material.dart';
import 'kkevo_ui.dart';

enum RoyalButtonVariant { gold, outline, ghost, emerald, danger }

class RoyalButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final RoyalButtonVariant variant;
  final double? width;
  final double height, fontSize;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  const RoyalButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = RoyalButtonVariant.gold,
    this.width,
    this.height = 52,
    this.padding,
    this.fontSize = 14,
    this.isLoading = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: KkevoButton(
        label: label,
        leading: icon,
        onPressed: onPressed,
        busy: isLoading,
        secondary:
            variant == RoyalButtonVariant.outline ||
            variant == RoyalButtonVariant.ghost,
      ),
    ),
  );
}
