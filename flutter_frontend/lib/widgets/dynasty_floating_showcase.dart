import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';
import 'floating_dynasty_card.dart';

class DynastyFloatingShowcase extends StatefulWidget {
  final int initialTier;
  final VoidCallback? onExploreDetails;

  const DynastyFloatingShowcase({
    super.key,
    this.initialTier = 1,
    this.onExploreDetails,
  });

  @override
  State<DynastyFloatingShowcase> createState() => _DynastyFloatingShowcaseState();
}

class _DynastyFloatingShowcaseState extends State<DynastyFloatingShowcase> {
  late int _selectedTier;
  String? _activeMemberId;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.initialTier;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    final allMembers = FloatingDynastyMemberData.royalShowcaseList;
    final filteredMembers = _selectedTier == 0
        ? allMembers
        : allMembers.where((m) => m.generationTier == _selectedTier).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Bar: Fish Audio-style generation selector & live voice counter
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 680;

            final leftInfo = Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RoyalTheme.brightGold.withValues(alpha: 0.15),
                    border: Border.all(
                      color: RoyalTheme.brightGold.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Icon(
                    Icons.record_voice_over_rounded,
                    color: RoyalTheme.brightGold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARCHIVES ORALES & VISAGES DU SANG',
                      style: GoogleFonts.cinzel(
                        fontSize: isCompact ? 11.5 : 13.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: RoyalTheme.brightGold,
                      ),
                    ),
                    Text(
                      'Visages réels des aïeux et transmissions orales numérisées',
                      style: GoogleFonts.inter(
                        fontSize: isCompact ? 10.5 : 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            );

            final chips = Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTierChip(0, 'Tout Voir (6)'),
                _buildTierChip(1, '👑 Gen 1 • Anciens'),
                _buildTierChip(2, '🗡️ Gen 2 • Héritiers'),
                _buildTierChip(3, '🌿 Gen 3 • Jeunesse'),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftInfo,
                  const SizedBox(height: 12),
                  chips,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                leftInfo,
                chips,
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Floating Levitation Cards Stage
        // In Fish Audio, cards levitate with smooth harmonic sine motion
        if (isMobile) ...[
          // On Mobile Galaxy S25 Ultra: Smooth horizontal floating snap carousel
          SizedBox(
            height: 290,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: FloatingDynastyCard(
                    member: member,
                    floatPhase: index * 1.05,
                    floatAmplitudeY: 8.0,
                    floatAmplitudeX: 4.0,
                    floatDuration: Duration(milliseconds: 3200 + (index * 400)),
                    isSelected: _activeMemberId == member.id,
                    onTap: () {
                      setState(() => _activeMemberId = member.id);
                    },
                  ),
                );
              },
            ),
          ),
        ] else ...[
          // On Desktop / Tablet: Organic multi-card floating grid with phase shifts
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisExtent: 275,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: filteredMembers.length,
            itemBuilder: (context, index) {
              final member = filteredMembers[index];
              return FloatingDynastyCard(
                member: member,
                floatPhase: index * 0.95,
                floatAmplitudeY: 10.0,
                floatAmplitudeX: 6.0,
                floatDuration: Duration(milliseconds: 3500 + (index * 350)),
                isSelected: _activeMemberId == member.id,
                onTap: () {
                  setState(() => _activeMemberId = member.id);
                },
              );
            },
          ),
        ],

        const SizedBox(height: 16),

        // Live Audio Equalizer Sub-Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: RoyalTheme.brightGold.withValues(alpha: isDark ? 0.08 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: RoyalTheme.brightGold.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Text('🎧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Touchez un souverain pour écouter son chant sacré et découvrir son proverbe de chefferie.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RoyalTheme.lightGold : const Color(0xFF6B4508),
                  ),
                ),
              ),
              if (widget.onExploreDetails != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: widget.onExploreDetails,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: RoyalTheme.brightGold),
                  label: Text(
                    'Arbre Vivant',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: RoyalTheme.brightGold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierChip(int tier, String label) {
    final isSelected = _selectedTier == tier;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTier = tier);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? RoyalTheme.brightGold
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF161925)
                  : const Color(0xFFEDE8DD)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? RoyalTheme.brightGold
                : RoyalTheme.brightGold.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: RoyalTheme.brightGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : null,
          ),
        ),
      ),
    );
  }
}
