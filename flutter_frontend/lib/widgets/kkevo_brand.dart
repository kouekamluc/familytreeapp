import 'package:flutter/material.dart';
import '../config/royal_theme.dart';
import 'kkevo_symbols.dart';

/// Eban: preserve the four gridded panels and four enclosing loops in the
/// supplied Akan symbol. A vector stays sharp from a toolbar to a launcher.
class KkevoMark extends StatelessWidget {
  final double size;
  final Color? color;
  final bool badge;
  const KkevoMark({super.key, this.size = 48, this.color, this.badge = true});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Kkevo Family',
    image: true,
    child: Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .13),
      decoration: badge
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(size * .28),
            )
          : null,
      child: CustomPaint(
        painter: EbanPainter(
          color ??
              (badge
                  ? RoyalTheme.greenInk
                  : Theme.of(context).colorScheme.primary),
        ),
      ),
    ),
  );
}

class KkevoBrand extends StatelessWidget {
  final double size;
  const KkevoBrand({super.key, this.size = 42});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      KkevoMark(size: size),
      const SizedBox(width: 12),
      Text(
        'kkevo family',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -.7,
        ),
      ),
    ],
  );
}

class EbanPainter extends CustomPainter {
  final Color color;
  const EbanPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final shape = Path()..fillType = PathFillType.evenOdd;
    shape.addRect(const Rect.fromLTWH(38, 38, 124, 124));
    final loop = Path()
      ..moveTo(69, 38)
      ..arcTo(const Rect.fromLTWH(69, 7, 62, 62), 3.14159265, 3.14159265, false)
      ..lineTo(119, 38)
      ..arcTo(const Rect.fromLTWH(81, 19, 38, 38), 0, -3.14159265, false)
      ..close();
    for (var side = 0; side < 4; side++) {
      canvas.save();
      canvas.translate(100, 100);
      canvas.rotate(side * 3.14159265 / 2);
      canvas.translate(-100, -100);
      canvas.drawPath(loop, paint);
      canvas.restore();
    }
    for (final x in [51.0, 111.0]) {
      for (final y in [51.0, 111.0]) {
        for (var col = 0; col < 3; col++) {
          for (var row = 0; row < 3; row++) {
            shape.addRect(Rect.fromLTWH(x + col * 14, y + row * 14, 10, 10));
          }
        }
      }
    }
    canvas.drawPath(shape, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(EbanPainter oldDelegate) => oldDelegate.color != color;
}

class FamilyConnectionsIllustration extends StatelessWidget {
  final double size;
  const FamilyConnectionsIllustration({super.key, this.size = 200});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * .87,
            height: size * .87,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? RoyalTheme.cardDark
                  : RoyalTheme.mint,
              shape: BoxShape.circle,
            ),
          ),
          CustomPaint(size: Size.square(size), painter: _FamilyOrbitPainter()),
          Positioned(
            bottom: size * .08,
            right: size * .1,
            child: KkevoMark(size: size * .24),
          ),
          Positioned(
            left: size * .05,
            top: size * .26,
            child: FriendlyFamilyFace(
              color: RoyalTheme.coral,
              variant: 0,
              size: size * .36,
            ),
          ),
          Positioned(
            right: size * .1,
            top: size * .02,
            child: FriendlyFamilyFace(
              color: RoyalTheme.blue,
              variant: 1,
              size: size * .4,
            ),
          ),
          Positioned(
            bottom: size * .02,
            left: size * .26,
            child: FriendlyFamilyFace(
              color: RoyalTheme.brightGold,
              variant: 2,
              size: size * .34,
            ),
          ),
          Positioned(
            top: 3,
            left: size * .2,
            child: KkevoSymbol(FamilySymbol.heart, size: size * .13),
          ),
          Positioned(
            right: size * .03,
            bottom: size * .37,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: RoyalTheme.darkGold,
              size: 23,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FamilyOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .24, size.height * .48)
      ..quadraticBezierTo(
        size.width * .4,
        size.height * .22,
        size.width * .7,
        size.height * .26,
      )
      ..quadraticBezierTo(
        size.width * .96,
        size.height * .62,
        size.width * .5,
        size.height * .81,
      )
      ..quadraticBezierTo(
        size.width * .19,
        size.height * .85,
        size.width * .24,
        size.height * .48,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = RoyalTheme.green.withValues(alpha: .4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FamilyOrbitPainter oldDelegate) => false;
}
