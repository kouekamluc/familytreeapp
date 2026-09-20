import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/heritage_key_sheet.dart';
import '../../widgets/royal_button.dart';
import '../../widgets/floating_dynasty_card.dart';

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

class _MobileWelcomeViewState extends State<MobileWelcomeView>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAutoLoggingIn = false;

  final List<Map<String, dynamic>> _features = [
    {
      'tag': 'TAPISSERIE SACRÉE',
      'title': 'Arbre Royal & Généalogie Vivante',
      'desc':
          'Explorez 4 générations royales sur une toile infinie et fluide, honorant le berceau de Bandjoun et le totem du Léopard.',
      'icon': Icons.account_tree_rounded,
      'stats': '71 Membres • 4 Générations • Bandjoun',
      'member': FloatingDynastyMemberData.royalShowcaseList[0],
    },
    {
      'tag': 'RÉALITÉ COUTUMIÈRE',
      'title': 'Parenté, Alliances & Lignées Directes',
      'desc':
          'Résolution intelligente des degrés de parenté, célébration des alliances multiples (polygamie) et respect des enfants nés hors mariage.',
      'icon': Icons.hub_rounded,
      'stats': 'Calculateur Coutumier • Multi-Épouses • Lignées Pures',
      'member': FloatingDynastyMemberData.royalShowcaseList[1],
    },
    {
      'tag': 'SOUVERAINETÉ NUMÉRIQUE',
      'title': 'Coffre-Fort & Clés d\'Héritage',
      'desc':
          'Accès chiffré sans mot de passe via Clés d\'Héritage royales. Données pérennes migrées en toute sécurité sur PostgreSQL.',
      'icon': Icons.vpn_key_rounded,
      'stats': 'PostgreSQL • JWT • Clés Dédiées par Rôle',
      'member': FloatingDynastyMemberData.royalShowcaseList[2],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _quickLoginWithKey(String key) async {
    HapticFeedback.heavyImpact();
    setState(() => _isAutoLoggingIn = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tree = Provider.of<TreeProvider>(context, listen: false);
    final ok = await auth.loginWithHeritageKey(key);
    if (ok) {
      await tree.loadData(
        targetTreeId: auth.invitedTreeId,
        targetPersonId: auth.invitedPersonId,
      );
      if (mounted) {
        widget.onExplore();
      }
    } else {
      if (mounted) {
        setState(() => _isAutoLoggingIn = false);
        HeritageKeySheet.show(context, onLoginSuccess: widget.onExplore);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080A10) : const Color(0xFFF9F7F2),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Sacred Gold Glow
            Positioned(
              top: -80,
              left: -40,
              right: -40,
              height: 320,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          RoyalTheme.brightGold.withValues(alpha: isDark ? 0.20 : 0.14),
                          RoyalTheme.primaryGold.withValues(alpha: isDark ? 0.08 : 0.05),
                          Colors.transparent,
                        ],
                        radius: 0.85 * _pulseAnimation.value,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main Content Layout
            Column(
              children: [
                const SizedBox(height: 14),

                // Top Royal Crest Medallion with Subtle Pulse
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF131722) : Colors.white,
                          border: Border.all(
                            color: RoyalTheme.brightGold,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: RoyalTheme.brightGold.withValues(alpha: isDark ? 0.45 : 0.25),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Dynasty Title Header
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFDF73), Color(0xFFD4AF37), Color(0xFFB8860B)],
                  ).createShader(bounds),
                  child: Text(
                    'KKEVO ROYAL DYNASTY',
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BERCEAU DE BANDJOUN',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: isDark ? RoyalTheme.lightGold : const Color(0xFF855B14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('🐆', style: TextStyle(fontSize: 11)),
                  ],
                ),

                const SizedBox(height: 14),

                // Feature Carousel Cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (idx) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentPage = idx);
                    },
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      final item = _features[index];
                      final member = item['member'] as FloatingDynastyMemberData;
                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: FloatingDynastyCard(
                              member: member,
                              floatPhase: index * 1.2,
                              floatAmplitudeY: 6.0,
                              floatAmplitudeX: 3.5,
                              floatDuration: Duration(milliseconds: 3200 + (index * 400)),
                              isSelected: _currentPage == index,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Carousel Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _features.length,
                    (idx) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == idx ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _currentPage == idx
                            ? RoyalTheme.brightGold
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Quick Demo Key 1-Tap Pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: _isAutoLoggingIn
                        ? null
                        : () => _quickLoginWithKey('KKEVO-ROYAL-2026-ROOT'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141723) : const Color(0xFFF7F2E7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: RoyalTheme.brightGold.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: RoyalTheme.brightGold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CLÉ ROYALE DÉMO (1-TAP)',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: RoyalTheme.brightGold,
                                  ),
                                ),
                                Text(
                                  'KKEVO-ROYAL-2026-ROOT',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isAutoLoggingIn)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: RoyalTheme.brightGold),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: RoyalTheme.brightGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Entrer ➔',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: RoyalTheme.brightGold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Action Dock
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primary Gold Enter Vault CTA
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: RoyalButton(
                          label: 'Explorer la Dynastie (Accès Libre)',
                          icon: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 18),
                          variant: RoyalButtonVariant.gold,
                          fontSize: 14,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            widget.onExplore();
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Secondary Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? RoyalTheme.brightGold.withValues(alpha: 0.5)
                                  : const Color(0xFFB8860B),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.02),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            HeritageKeySheet.show(context, onLoginSuccess: widget.onExplore);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.key_rounded, color: RoyalTheme.brightGold, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Déverrouiller avec Clé d\'Héritage',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

