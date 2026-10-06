import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/royal_theme.dart';
import 'kkevo_brand.dart';
import 'kkevo_symbols.dart';

class KkevoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool secondary, busy;
  const KkevoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.secondary = false,
    this.busy = false,
  });
  @override
  State<KkevoButton> createState() => _KkevoButtonState();
}

class _KkevoButtonState extends State<KkevoButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.busy;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Listener(
        onPointerDown: (_) {
          if (enabled) setState(() => _pressed = true);
        },
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: reduced ? 0 : 100),
          transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: widget.secondary
                      ? scheme.outline
                      : RoyalTheme.greenDepth,
                  offset: Offset(0, _pressed ? 0 : 5),
                ),
            ],
          ),
          child: FilledButton(
            onPressed: !enabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onPressed!();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: widget.secondary
                  ? scheme.surface
                  : scheme.primary,
              foregroundColor: widget.secondary
                  ? scheme.onSurface
                  : scheme.onPrimary,
              side: widget.secondary
                  ? BorderSide(color: scheme.outline, width: 2)
                  : null,
            ),
            child: widget.busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.secondary
                          ? scheme.onSurface
                          : scheme.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null || widget.leading != null) ...[
                        widget.leading ?? Icon(widget.icon, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: AppText(
                          widget.label,
                          textAlign: TextAlign.center,
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

class KkevoPanel extends StatelessWidget {
  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  const KkevoPanel({
    super.key,
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: tint == null
          ? Theme.of(context).colorScheme.surface
          : Color.alphaBlend(
              tint!.withValues(alpha: .07),
              Theme.of(context).colorScheme.surface,
            ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline,
        width: 1.5,
      ),
    ),
    child: child,
  );
}

class KkevoIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const KkevoIcon(
    this.icon, {
    super.key,
    this.color = RoyalTheme.green,
    this.size = 52,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(size * .3),
      border: Border.all(color: color.withValues(alpha: .25), width: 1.5),
    ),
    child: KkevoSymbol.forIcon(icon) != null
        ? Center(
            child: KkevoSymbol(KkevoSymbol.forIcon(icon)!, size: size * .7),
          )
        : Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Color.lerp(color, Colors.white, .35)
                : RoyalTheme.accentText(context, color),
            size: size * .48,
          ),
  );
}

/// Existing milestones presented as a connected, freely accessible journey.
class KkevoChoiceTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const KkevoChoiceTile({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color = RoyalTheme.green,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 140,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          border: Border.all(
            color: selected ? RoyalTheme.greenDepth : scheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  KkevoIcon(icon, color: color, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppText(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? RoyalTheme.accentText(context, RoyalTheme.green)
                        : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KkevoConnectionPreview extends StatelessWidget {
  final String from, to;
  final bool directional;
  const KkevoConnectionPreview({
    super.key,
    required this.from,
    required this.to,
    this.directional = true,
  });
  @override
  Widget build(BuildContext context) {
    Widget person(String name, Color color) => Column(
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: .5), width: 1.5),
          ),
          child: Text(
            name
                .trim()
                .split(RegExp(r'\s+'))
                .where((part) => part.isNotEmpty)
                .take(2)
                .map((part) => part.characters.first)
                .join()
                .toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: RoyalTheme.accentText(context, color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
    final arrow = Icon(
      directional ? Icons.arrow_forward_rounded : Icons.swap_horiz_rounded,
      color: RoyalTheme.accentText(context, RoyalTheme.blue),
    );
    return LayoutBuilder(
      builder: (ctx, box) {
        if (box.maxWidth < 260 || MediaQuery.textScalerOf(ctx).scale(1) > 1.5) {
          return Column(
            children: [
              person(from, RoyalTheme.blue),
              Padding(
                padding: const EdgeInsets.all(8),
                child: RotatedBox(quarterTurns: 1, child: arrow),
              ),
              person(to, RoyalTheme.primaryGold),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: person(from, RoyalTheme.blue)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: arrow,
            ),
            Expanded(child: person(to, RoyalTheme.primaryGold)),
          ],
        );
      },
    );
  }
}

class KkevoJourneyStep extends StatefulWidget {
  final int index;
  final String title, subtitle;
  final IconData icon;
  final bool done, active, last;
  final Color color;
  final VoidCallback onTap;
  const KkevoJourneyStep({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.active,
    required this.last,
    required this.color,
    required this.onTap,
  });
  @override
  State<KkevoJourneyStep> createState() => _KkevoJourneyStepState();
}

class _KkevoJourneyStepState extends State<KkevoJourneyStep> {
  bool _pressed = false;
  static double bend(int index) => switch (index % 4) {
    1 => 0,
    2 => -.48,
    3 => 0,
    _ => .48,
  };
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 120,
    );
    final fill = widget.active || widget.done
        ? widget.color
        : scheme.surfaceContainerHighest;
    final depth = widget.active || widget.done
        ? Color.lerp(widget.color, Colors.black, .24)!
        : scheme.outline;
    return LayoutBuilder(
      builder: (context, constraints) {
        double xAt(int index) =>
            constraints.maxWidth / 2 + bend(index) * constraints.maxWidth * .38;
        final x = xAt(widget.index);
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _JourneyPathPainter(
                    x: x,
                    startX: widget.index == 1
                        ? x
                        : (x + xAt(widget.index - 1)) / 2,
                    endX: (x + xAt(widget.index + 1)) / 2,
                    first: widget.index == 1,
                    last: widget.last,
                    color: scheme.outline.withValues(alpha: .5),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment(bend(widget.index) * 2, 0),
              child: SizedBox(
                width: constraints.maxWidth * .62,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 26),
                  child: Column(
                    children: [
                      Semantics(
                        button: true,
                        label: context.tr(widget.title),
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _pressed = true),
                          onTapUp: (_) => setState(() => _pressed = false),
                          onTapCancel: () => setState(() => _pressed = false),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onTap();
                          },
                          child: AnimatedContainer(
                            duration: duration,
                            width: 84,
                            height: 78,
                            transform: Matrix4.translationValues(
                              0,
                              _pressed ? 6 : 0,
                              0,
                            ),
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(42),
                              border: Border.all(color: depth, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: depth,
                                  offset: Offset(0, _pressed ? 0 : 7),
                                ),
                              ],
                            ),
                            child: Center(
                              child: KkevoSymbol(
                                widget.done
                                    ? FamilySymbol.success
                                    : KkevoSymbol.forIcon(widget.icon) ??
                                          FamilySymbol.tree,
                                size: 46,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onTap();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                AppText(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  widget.subtitle,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _JourneyPathPainter extends CustomPainter {
  final double x, startX, endX;
  final bool first, last;
  final Color color;
  const _JourneyPathPainter({
    required this.x,
    required this.startX,
    required this.endX,
    required this.first,
    required this.last,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (!first) {
      path.moveTo(startX, 0);
      path.cubicTo(startX, 26, x, 26, x, 57);
    } else {
      path.moveTo(x, 57);
    }
    if (!last) {
      path.cubicTo(
        x,
        size.height - 32,
        endX,
        size.height - 32,
        endX,
        size.height,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_JourneyPathPainter old) =>
      old.x != x ||
      old.startX != startX ||
      old.endX != endX ||
      old.color != color ||
      old.first != first ||
      old.last != last;
}

/// Kept as a compatibility name for existing family layouts.
class FamilyGrove extends StatelessWidget {
  final double size;
  const FamilyGrove({super.key, this.size = 240});
  @override
  Widget build(BuildContext context) =>
      FamilyConnectionsIllustration(size: size);
}

Future<void> showFamilySuccess(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .8, end: 1),
          duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(ctx) ? 0 : 240,
          ),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: const KkevoSymbol(FamilySymbol.success, size: 88),
        ),
        const SizedBox(height: 22),
        AppText(
          title,
          style: Theme.of(ctx).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        AppText(message, textAlign: TextAlign.center),
      ],
    ),
    actions: [
      KkevoButton(label: 'Continue', onPressed: () => Navigator.pop(ctx)),
    ],
  ),
);
