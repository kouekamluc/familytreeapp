import 'package:flutter/material.dart';
import '../config/royal_theme.dart';

enum FamilySymbol {
  home,
  tree,
  people,
  links,
  profile,
  memory,
  invite,
  heart,
  success,
}

/// One rounded vector vocabulary shared by navigation and family tasks.
class KkevoSymbol extends StatelessWidget {
  final FamilySymbol symbol;
  final double size;
  final bool muted;
  const KkevoSymbol(
    this.symbol, {
    super.key,
    this.size = 32,
    this.muted = false,
  });
  static FamilySymbol? forIcon(IconData icon) {
    if ([
      Icons.account_tree_rounded,
      Icons.account_tree_outlined,
      Icons.arrow_upward_rounded,
    ].contains(icon)) {
      return FamilySymbol.tree;
    }
    if ([
      Icons.person_add_alt_1_rounded,
      Icons.child_care_rounded,
      Icons.person_rounded,
    ].contains(icon)) {
      return FamilySymbol.profile;
    }
    if ([
      Icons.people_alt_rounded,
      Icons.people_alt_outlined,
      Icons.diversity_1_rounded,
    ].contains(icon)) {
      return FamilySymbol.people;
    }
    if ([
      Icons.link_rounded,
      Icons.hub_rounded,
      Icons.hub_outlined,
      Icons.route_rounded,
    ].contains(icon)) {
      return FamilySymbol.links;
    }
    if ([
      Icons.auto_stories_rounded,
      Icons.auto_stories_outlined,
      Icons.edit_note_rounded,
    ].contains(icon)) {
      return FamilySymbol.memory;
    }
    if ([
      Icons.favorite_rounded,
      Icons.favorite_border_rounded,
      Icons.favorite_outline_rounded,
    ].contains(icon)) {
      return FamilySymbol.heart;
    }
    if (icon == Icons.mail_outline_rounded) return FamilySymbol.invite;
    if (icon == Icons.check_rounded) return FamilySymbol.success;
    return null;
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SymbolPainter(
          symbol,
          muted,
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    ),
  );
}

class _SymbolPainter extends CustomPainter {
  final FamilySymbol symbol;
  final bool muted, dark;
  _SymbolPainter(this.symbol, this.muted, this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final outline = muted
        ? (dark ? const Color(0xFFB5C9BB) : const Color(0xFF77877C))
        : (dark ? const Color(0xFFEDF5ED) : RoyalTheme.ink);
    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Color tone(Color color) =>
        muted ? (dark ? RoyalTheme.cardDark : RoyalTheme.cardLight) : color;
    void round(Rect rect, Color color, [double radius = 9]) {
      final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(shape, Paint()..color = tone(color));
      canvas.drawRRect(shape, stroke);
    }

    void head(double x, double y, double radius, Color color) {
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = tone(color));
      canvas.drawCircle(Offset(x, y), radius, stroke);
    }

    switch (symbol) {
      case FamilySymbol.home:
        round(const Rect.fromLTWH(12, 25, 40, 32), RoyalTheme.green);
        canvas.drawPath(
          Path()
            ..moveTo(7, 29)
            ..lineTo(27, 10)
            ..quadraticBezierTo(32, 5, 37, 10)
            ..lineTo(57, 29),
          stroke,
        );
        round(const Rect.fromLTWH(25, 36, 14, 21), Colors.white, 5);
      case FamilySymbol.tree:
        canvas.drawLine(const Offset(32, 23), const Offset(32, 35), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(14, 42)
            ..lineTo(14, 35)
            ..lineTo(50, 35)
            ..lineTo(50, 42),
          stroke,
        );
        round(const Rect.fromLTWH(21, 7, 22, 20), RoyalTheme.green, 7);
        round(const Rect.fromLTWH(4, 40, 22, 18), RoyalTheme.green, 7);
        round(const Rect.fromLTWH(38, 40, 22, 18), RoyalTheme.primaryGold, 7);
      case FamilySymbol.people:
        round(const Rect.fromLTWH(5, 35, 24, 21), RoyalTheme.blue, 10);
        round(const Rect.fromLTWH(35, 35, 24, 21), RoyalTheme.coral, 10);
        head(17, 22, 10, RoyalTheme.blue);
        head(47, 22, 10, RoyalTheme.coral);
      case FamilySymbol.links:
        canvas.drawPath(
          Path()
            ..moveTo(21, 24)
            ..cubicTo(43, 24, 21, 45, 43, 45),
          stroke,
        );
        head(16, 21, 12, RoyalTheme.blue);
        head(48, 45, 12, RoyalTheme.green);
        canvas.drawLine(const Offset(12, 21), const Offset(20, 21), stroke);
        canvas.drawLine(const Offset(48, 41), const Offset(48, 49), stroke);
      case FamilySymbol.profile:
        round(const Rect.fromLTWH(10, 36, 44, 23), RoyalTheme.blue, 12);
        head(32, 20, 13, RoyalTheme.primaryGold);
      case FamilySymbol.memory:
        round(const Rect.fromLTWH(7, 12, 50, 42), RoyalTheme.coral, 8);
        canvas.drawLine(const Offset(32, 13), const Offset(32, 54), stroke);
        canvas.drawLine(const Offset(15, 26), const Offset(24, 26), stroke);
        canvas.drawLine(const Offset(40, 26), const Offset(49, 26), stroke);
        canvas.drawLine(const Offset(15, 36), const Offset(24, 36), stroke);
      case FamilySymbol.invite:
        round(const Rect.fromLTWH(6, 16, 52, 37), RoyalTheme.primaryGold, 9);
        canvas.drawPath(
          Path()
            ..moveTo(8, 19)
            ..lineTo(28, 35)
            ..quadraticBezierTo(32, 38, 36, 35)
            ..lineTo(56, 19),
          stroke,
        );
      case FamilySymbol.heart:
        final heart = Path()
          ..moveTo(32, 54)
          ..cubicTo(1, 34, 2, 8, 19, 10)
          ..quadraticBezierTo(28, 10, 32, 20)
          ..quadraticBezierTo(36, 10, 45, 10)
          ..cubicTo(62, 8, 63, 34, 32, 54)
          ..close();
        canvas.drawPath(heart, Paint()..color = tone(RoyalTheme.coral));
        canvas.drawPath(heart, stroke);
      case FamilySymbol.success:
        head(32, 32, 25, RoyalTheme.green);
        canvas.drawPath(
          Path()
            ..moveTo(19, 32)
            ..lineTo(28, 41)
            ..lineTo(45, 23),
          stroke..strokeWidth = 5,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SymbolPainter oldDelegate) =>
      symbol != oldDelegate.symbol ||
      muted != oldDelegate.muted ||
      dark != oldDelegate.dark;
}

/// Decorative artwork, never a substitute for a real family portrait.
class FriendlyFamilyFace extends StatelessWidget {
  final Color color;
  final int variant;
  final double size;
  const FriendlyFamilyFace({
    super.key,
    required this.color,
    required this.variant,
    required this.size,
  });
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FacePainter(color, variant)),
    ),
  );
}

class _FacePainter extends CustomPainter {
  final Color color;
  final int variant;
  _FacePainter(this.color, this.variant);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 80);
    canvas.drawCircle(
      const Offset(40, 43),
      35,
      Paint()..color = Color.lerp(color, Colors.black, .13)!,
    );
    canvas.drawCircle(const Offset(40, 39), 35, Paint()..color = color);
    final face = [
      const Color(0xFFDA956E),
      const Color(0xFFF6CDAC),
      const Color(0xFFAE7051),
    ][variant % 3];
    final hair = variant == 1 ? const Color(0xFFEFF2EA) : RoyalTheme.ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 51, 48, 24),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFFFFF9EC),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(21, 15, 38, 40),
        const Radius.circular(17),
      ),
      Paint()..color = hair,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(23, 23, 34, 36),
        const Radius.circular(15),
      ),
      Paint()..color = face,
    );
    canvas.drawPath(
      Path()
        ..moveTo(21, 27)
        ..quadraticBezierTo(22, 9, 40, 15)
        ..quadraticBezierTo(60, 10, 60, 32)
        ..quadraticBezierTo(48, 28, 44, 21)
        ..quadraticBezierTo(33, 30, 21, 27),
      Paint()..color = hair,
    );
    final line = Paint()
      ..color = RoyalTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(32, 38), const Offset(32, 40), line);
    canvas.drawLine(const Offset(48, 38), const Offset(48, 40), line);
    canvas.drawPath(
      Path()
        ..moveTo(35, 48)
        ..quadraticBezierTo(40, 53, 45, 48),
      line,
    );
    if (variant == 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(26, 33, 12, 12),
          const Radius.circular(4),
        ),
        line,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(42, 33, 12, 12),
          const Radius.circular(4),
        ),
        line,
      );
      canvas.drawLine(const Offset(38, 38), const Offset(42, 38), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) =>
      color != oldDelegate.color || variant != oldDelegate.variant;
}
