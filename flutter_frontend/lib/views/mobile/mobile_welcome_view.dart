import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/royal_theme.dart';

class MobileWelcomeView extends StatefulWidget {
  final VoidCallback onExplore;
  final VoidCallback onSignIn;

  const MobileWelcomeView({
    super.key,
    required this.onExplore,
    required this.onSignIn,
  });

  @override
  State<MobileWelcomeView> createState() => _MobileWelcomeViewState();
}

class _Chapter {
  final String label;
  final String title;
  final String description;
  final IconData icon;

  const _Chapter(this.label, this.title, this.description, this.icon);
}

class _MobileWelcomeViewState extends State<MobileWelcomeView> {
  static const _chapters = [
    _Chapter(
      '01 / RACINES',
      'Chaque histoire a une place.',
      'Retrouvez les personnes, les liens et les générations qui composent votre famille.',
      Icons.account_tree_rounded,
    ),
    _Chapter(
      '02 / SOUVENIRS',
      'Faites vivre leur mémoire.',
      'Ajoutez des événements et des souvenirs aux histoires que vous souhaitez préserver.',
      Icons.auto_stories_rounded,
    ),
    _Chapter(
      '03 / TRANSMISSION',
      'Un héritage à partager avec soin.',
      'Accédez à votre arbre avec votre compte ou votre Clé d’Héritage personnelle.',
      Icons.key_rounded,
    ),
  ];

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page == _chapters.length - 1) {
      widget.onExplore();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ink = dark ? const Color(0xFFF9F5EB) : const Color(0xFF241F16);
    final muted = dark ? const Color(0xFFC8C2B7) : const Color(0xFF635B50);
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0E1016) : const Color(0xFFFAF8F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/logo.png', width: 38, height: 38),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'KKEVO',
                            style: GoogleFonts.cinzel(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.3,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onSignIn,
                          child: const Text('Se connecter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: math.min(
                        470.0,
                        math.max(350.0, constraints.maxHeight - 230),
                      ),
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _chapters.length,
                        onPageChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _page = value);
                        },
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  key: ValueKey(index),
                                  tween: Tween(begin: 0, end: 1),
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 950),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, progress, child) =>
                                      CustomPaint(
                                        painter: _HeritageIllustration(
                                          progress,
                                          dark,
                                          chapter.icon,
                                        ),
                                        child: const SizedBox.expand(),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                chapter.label,
                                style: GoogleFonts.inter(
                                  color: RoyalTheme.darkGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                chapter.title,
                                style: GoogleFonts.cinzel(
                                  color: ink,
                                  fontSize: 27,
                                  height: 1.18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                chapter.description,
                                style: GoogleFonts.inter(
                                  color: muted,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _chapters.length,
                        (index) => AnimatedContainer(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? RoyalTheme.primaryGold
                                : muted.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(
                          _page == _chapters.length - 1
                              ? 'Explorer l’exemple'
                              : 'Continuer',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L’exemple contient des données fictives et ne modifie aucun arbre.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeritageIllustration extends CustomPainter {
  final double progress;
  final bool dark;
  final IconData icon;
  const _HeritageIllustration(this.progress, this.dark, this.icon);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final gold = RoyalTheme.primaryGold;
    final surface = dark ? const Color(0xFF20242D) : const Color(0xFFF1E9DA);
    canvas.drawCircle(
      center,
      math.min(size.width * 0.43, size.height * 0.48),
      Paint()..color = gold.withValues(alpha: dark ? 0.13 : 0.11),
    );
    final anchors = [
      Offset(center.dx - size.width * 0.29, center.dy - size.height * 0.29),
      Offset(center.dx + size.width * 0.29, center.dy - size.height * 0.29),
      Offset(center.dx - size.width * 0.29, center.dy + size.height * 0.29),
      Offset(center.dx + size.width * 0.29, center.dy + size.height * 0.29),
    ];
    final line = Paint()
      ..color = gold.withValues(alpha: 0.64)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final anchor in anchors) {
      canvas.drawLine(center, Offset.lerp(center, anchor, progress)!, line);
      canvas.drawCircle(anchor, 19 * progress, Paint()..color = surface);
      canvas.drawCircle(anchor, 5 * progress, Paint()..color = gold);
    }
    canvas.drawCircle(center, 58 * progress, Paint()..color = surface);
    canvas.drawCircle(
      center,
      58 * progress,
      Paint()
        ..color = gold
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    final glyph = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 47 * progress,
          color: gold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, center - Offset(glyph.width / 2, glyph.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HeritageIllustration oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.dark != dark ||
      oldDelegate.icon != icon;
}
