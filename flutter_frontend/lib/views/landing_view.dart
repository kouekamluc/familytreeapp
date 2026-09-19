import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../providers/tree_provider.dart';
import '../widgets/royal_card.dart';

class LandingView extends StatelessWidget {
  final VoidCallback onExploreTree;
  final VoidCallback onOpenKinship;
  final VoidCallback onOpenDirectory;

  const LandingView({
    super.key,
    required this.onExploreTree,
    required this.onOpenKinship,
    required this.onOpenDirectory,
  });

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final memberCount = treeProvider.people.length;
    final ancestorCount = treeProvider.people.where((p) => p.isAncestor).length;
    final livingCount = treeProvider.people.where((p) => p.isLiving).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF161822),
                          RoyalTheme.obsidianDark,
                        ]
                      : [
                          const Color(0xFFF5EFE6),
                          RoyalTheme.alabasterLight,
                        ],
                ),
              ),
              child: Column(
                children: [
                  // Royal Crest Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: RoyalTheme.primaryGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: RoyalTheme.primaryGold.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, color: RoyalTheme.brightGold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'AFRICAN ROYAL DYNASTY ARCHIVE',
                          style: GoogleFonts.cinzel(
                            color: RoyalTheme.brightGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Honor Your Lineage.\nPreserve Every Generation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      height: 1.25,
                      color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'An imperial genealogical platform engineered to safeguard family dynasties, customary totems, and ancestral bloodlines across generations.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.5,
                        color: isDark ? const Color(0xFFB0A89F) : const Color(0xFF57534E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // CTA Buttons
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.account_tree_rounded, color: Colors.black),
                        label: const Text(
                          'Explore Family Tree',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoyalTheme.brightGold,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 6,
                        ),
                        onPressed: onExploreTree,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome, color: RoyalTheme.brightGold),
                        label: const Text(
                          'Kinship Solver',
                          style: TextStyle(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: RoyalTheme.brightGold, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: onOpenKinship,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Dynasty Live Stats Showcase
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: RoyalCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Dynasty Members', '$memberCount', Icons.groups_outlined),
                          _buildDivider(),
                          _buildStatItem('Venerated Ancestors', '$ancestorCount', Icons.temple_buddhist_outlined),
                          _buildDivider(),
                          _buildStatItem('Living Descendants', '$livingCount', Icons.favorite_outline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pillars & Features Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARCHIVAL PILLARS',
                        style: GoogleFonts.cinzel(
                          color: RoyalTheme.brightGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Three Pillars of Imperial Lineage',
                        style: GoogleFonts.cinzel(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1C1917),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 720;
                          return isNarrow
                              ? Column(
                                  children: [
                                    _buildPillarCard(
                                      title: 'Vector Tree Visualization',
                                      desc: 'Interactive dual-orientation tree canvas with smooth vector lineage curves, wedding rings, and generation grouping.',
                                      icon: Icons.account_tree,
                                      onTap: onExploreTree,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPillarCard(
                                      title: 'Deep Kinship Solver',
                                      desc: 'Calculates exact biological degrees, African cultural titles (Mama, Papa, Reine-Mère), and visual bloodline ribbons.',
                                      icon: Icons.hub_outlined,
                                      onTap: onOpenKinship,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPillarCard(
                                      title: 'Cultural Heritage Registry',
                                      desc: 'Safeguards customary names, village of origin, clan totems, and generation tiers for future generations.',
                                      icon: Icons.menu_book_outlined,
                                      onTap: onOpenDirectory,
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildPillarCard(
                                        title: 'Vector Tree Engine',
                                        desc: 'Interactive dual-orientation tree canvas with smooth vector lineage curves, wedding rings, and generation grouping.',
                                        icon: Icons.account_tree,
                                        onTap: onExploreTree,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildPillarCard(
                                        title: 'Deep Kinship Solver',
                                        desc: 'Calculates exact biological degrees, African cultural titles (Mama, Papa, Reine-Mère), and visual bloodline ribbons.',
                                        icon: Icons.hub_outlined,
                                        onTap: onOpenKinship,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _buildPillarCard(
                                        title: 'Customary Registry',
                                        desc: 'Safeguards customary names, village of origin, clan totems, and generation tiers for future generations.',
                                        icon: Icons.menu_book_outlined,
                                        onTap: onOpenDirectory,
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: RoyalTheme.brightGold, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cinzel(fontSize: 28, fontWeight: FontWeight.w900, color: RoyalTheme.brightGold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 48, color: RoyalTheme.borderDark);
  }

  Widget _buildPillarCard({
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return RoyalCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RoyalTheme.primaryGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: RoyalTheme.brightGold, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Open Module',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: RoyalTheme.brightGold,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: RoyalTheme.brightGold),
            ],
          ),
        ],
      ),
    );
  }
}
