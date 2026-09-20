import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';
import '../widgets/royal_button.dart';
import '../widgets/dynasty_floating_showcase.dart';

class LandingView extends StatefulWidget {
  final VoidCallback onSignIn;
  final VoidCallback onJoin;
  final VoidCallback? onExploreDemo;

  const LandingView({
    super.key,
    required this.onSignIn,
    required this.onJoin,
    this.onExploreDemo,
  });

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // =========================================================
            // 1. HERO SECTION: Royal Authority & Value Proposition
            // =========================================================
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 40 : 68),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF151824),
                          const Color(0xFF0F1017),
                          RoyalTheme.obsidianDark,
                        ]
                      : [
                          const Color(0xFFFFFDF8),
                          const Color(0xFFFAF6ED),
                          const Color(0xFFF5EFE1),
                        ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      // Royal Emblem Crest
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF141722) : const Color(0xFFF9F5EC),
                          border: Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: RoyalTheme.brightGold.withValues(alpha: isDark ? 0.35 : 0.2),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          width: isMobile ? 68 : 88,
                          height: isMobile ? 68 : 88,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Prestigious Pill Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF181A22) : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: RoyalTheme.brightGold.withValues(alpha: 0.8),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: RoyalTheme.brightGold.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isMobile ? 'KKEVO ROYAL HERITAGE' : 'KKEVO ROYAL HERITAGE & LIVING LINEAGE',
                                style: GoogleFonts.cinzel(
                                  color: isDark ? RoyalTheme.lightGold : const Color(0xFF7A520C),
                                  fontSize: isMobile ? 10.5 : 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: isMobile ? 1.0 : 1.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Main Title
                      Text(
                        'Honor Your Ancestors.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          fontSize: isMobile ? 30 : 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: isMobile ? 0.6 : 1.2,
                          height: 1.15,
                          color: isDark ? const Color(0xFFFDFBF7) : const Color(0xFF1C1917),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFB8860B), Color(0xFFD4AF37), Color(0xFFC5A059)],
                        ).createShader(bounds),
                        child: Text(
                          'Unite Every Generation.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: isMobile ? 30 : 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: isMobile ? 0.6 : 1.2,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 740),
                        child: Text(
                          'The digital sanctuary for the Kkevo Family. Securely archive ancestral trees with museum-grade precision, calculate customary kinship across generations, preserve sacred oral lore, and pass down your royal bloodline.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 13.5 : 16,
                            height: 1.55,
                            color: isDark ? const Color(0xFFC7BFB5) : const Color(0xFF57534E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // CTAs Row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          if (widget.onExploreDemo != null)
                            RoyalButton(
                              label: isMobile ? 'Explore Dynasty Vault' : 'Explore Dynasty Vault (Instant Demo)',
                              icon: const Icon(Icons.flash_on_rounded, color: Colors.black, size: 16),
                              variant: RoyalButtonVariant.gold,
                              height: isMobile ? 44 : 52,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 26),
                              fontSize: isMobile ? 13 : 15,
                              onPressed: widget.onExploreDemo,
                            ),
                          RoyalButton(
                            label: 'Sign In to Private Vault',
                            icon: Icon(Icons.lock_open_rounded, size: 16, color: isDark ? RoyalTheme.lightGold : RoyalTheme.darkGold),
                            variant: RoyalButtonVariant.outline,
                            height: isMobile ? 44 : 52,
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 24),
                            fontSize: isMobile ? 13 : 15,
                            onPressed: widget.onSignIn,
                          ),
                          RoyalButton(
                            label: 'Join Dynasty Registry',
                            icon: Icon(Icons.how_to_reg_rounded, size: 16, color: isDark ? RoyalTheme.lightGold : RoyalTheme.darkGold),
                            variant: RoyalButtonVariant.outline,
                            height: isMobile ? 44 : 52,
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 22),
                            fontSize: isMobile ? 13 : 15,
                            onPressed: widget.onJoin,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Trust & Privacy Bullets
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _buildTrustBullet('End-to-End Privacy Protection', isDark),
                          _buildTrustBullet('African Royal Titles & Totems', isDark),
                          _buildTrustBullet('Sacred Oral Lore Encryption', isDark),
                          _buildTrustBullet('Printable Lineage Heirlooms', isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // =========================================================
            // 2. ILLUSTRATIVE DYNASTY SYSTEM SHOWCASE
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              color: isDark ? RoyalTheme.obsidianDark : const Color(0xFFFAF7F0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151722) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: RoyalTheme.brightGold.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fish Audio-Style Levitating Dynasty Showcase with Real People's Heads
                        DynastyFloatingShowcase(
                          initialTier: 0,
                          onExploreDetails: widget.onSignIn,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: RoyalTheme.borderDark),
                        const SizedBox(height: 16),

                        // Showcase Bottom Privacy Lock Strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: RoyalTheme.brightGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.3)),
                          ),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final isMobileStrip = c.maxWidth < 650;
                              if (isMobileStrip) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text('🔒', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Protected family records. Sign in to view live tree.',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? RoyalTheme.lightGold : const Color(0xFF6B4508),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: RoyalButton(
                                        label: 'Sign In to Enter Vault →',
                                        variant: RoyalButtonVariant.gold,
                                        height: 38,
                                        fontSize: 12.5,
                                        onPressed: widget.onSignIn,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Text('🔒', style: TextStyle(fontSize: 18)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Family Lineage records are strictly protected. Authenticate to view your live interactive tree.',
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? RoyalTheme.lightGold : const Color(0xFF6B4508),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  RoyalButton(
                                    label: 'Sign In to Enter Dashboard →',
                                    variant: RoyalButtonVariant.gold,
                                    height: 42,
                                    fontSize: 13,
                                    onPressed: widget.onSignIn,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // =========================================================
            // 3. HERITAGE NUMERICAL COUNTERS STRIP
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10121A) : const Color(0xFFFAF6ED),
                border: Border.symmetric(
                  horizontal: BorderSide(color: RoyalTheme.primaryGold.withValues(alpha: 0.25)),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCounterItem('4+', 'Generations Charted'),
                      _buildCounterItem('16+', 'Verified Kinship Links'),
                      _buildCounterItem('100%', 'End-to-End Privacy'),
                      _buildCounterItem('1-Click', 'Relative Addition'),
                      _buildCounterItem('Global', 'Diaspora Connected'),
                    ],
                  ),
                ),
              ),
            ),

            // =========================================================
            // 4. HOW IT WORKS: 3-STEP CLEAR PATHWAY
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              color: isDark ? RoyalTheme.obsidianDark : const Color(0xFFFBF8F2),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: RoyalTheme.brightGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'SIMPLICITY FOR ELDERS • INTUITIVE FOR YOUTH',
                          style: GoogleFonts.cinzel(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: RoyalTheme.brightGold,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'How the Royal Platform Works',
                        style: GoogleFonts.cinzel(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Building your family archive requires no technical expertise. Follow our simple, respectful 3-step pathway.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildStepCard(
                              number: '1',
                              title: 'Anchor Patriarch Roots',
                              description: 'Start with your earliest known elders. Enter honorary titles (e.g. Tadji, Fo, Ma), clan totems, and ancestral villages to ground your lineage.',
                              tag: '👑 Customary Title Preservation',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildStepCard(
                              number: '2',
                              title: 'Weave Living Lineages',
                              description: 'Link spouses and children with 1-click bond modals. Calculate multi-generational kinship automatically with African cultural honorifics.',
                              tag: '💍 Matrimonial & Child Links',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildStepCard(
                              number: '3',
                              title: 'Safeguard Imperial Lore',
                              description: 'Store oral histories, biographical traditions, and export beautiful heirloom pedigrees to pass down to future generations across the diaspora.',
                              tag: '📜 Museum-Grade Dynasty Archiving',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // =========================================================
            // 5. FOUR PILLARS OF IMPERIAL LINEAGE
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              color: isDark ? const Color(0xFF12141C) : const Color(0xFFFAF6ED),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      Text(
                        'FOUR PILLARS OF IMPERIAL LINEAGE',
                        style: GoogleFonts.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: RoyalTheme.brightGold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Engineered for Heritage & Continuity',
                        style: GoogleFonts.cinzel(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 38),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 2.1,
                        children: [
                          _buildPillarCard(
                            icon: Icons.account_tree_outlined,
                            title: 'Vector Pedigree Engine',
                            description: 'Interactive dual-orientation tree canvas with smooth vector curves, matrimonial rings, and generation grouping.',
                            isDark: isDark,
                          ),
                          _buildPillarCard(
                            icon: Icons.hub_outlined,
                            title: 'Customary Kinship Solver',
                            description: 'Calculates exact biological degrees and customary titles (Ma, Tadji, Fo, Reine-Mère) between any two living members.',
                            isDark: isDark,
                          ),
                          _buildPillarCard(
                            icon: Icons.book_outlined,
                            title: 'Sacred Customary Vault',
                            description: 'Safeguards village of origin, clan totems, noble titles, and generation tiers for diaspora descendants.',
                            isDark: isDark,
                          ),
                          _buildPillarCard(
                            icon: Icons.mic_external_on_outlined,
                            title: 'Oral Histories & Memoirs',
                            description: 'Records oral interviews, archival photos, and biographical folklore to safeguard imperial memories.',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // =========================================================
            // 6. ROYAL FOOTER
            // =========================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              color: isDark ? const Color(0xFF090A0E) : Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'KKEVO FAMILY',
                            style: GoogleFonts.cinzel(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.8,
                              color: RoyalTheme.brightGold,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            '•  Preserving our royal heritage, roots, and stories for generations to come.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        '© 2026 Kkevo Royal Lineage • All Rights Reserved',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBullet(String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('✓', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFD6D0C7) : const Color(0xFF44403C),
          ),
        ),
      ],
    );
  }



  Widget _buildCounterItem(String value, String label) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFB8860B), Color(0xFFD4AF37), Color(0xFFC5A059)],
          ).createShader(bounds),
          child: Text(
            value,
            style: GoogleFonts.cinzel(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required String tag,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161822) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RoyalTheme.primaryGold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFFD4AF37)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tag,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: RoyalTheme.brightGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RoyalTheme.primaryGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RoyalTheme.brightGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: RoyalTheme.brightGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
