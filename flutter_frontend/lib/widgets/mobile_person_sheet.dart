import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import '../utils/genealogy_helper.dart';
import 'monogram_medallion.dart';

class MobilePersonSheet extends StatelessWidget {
  final Person person;
  final VoidCallback onInspectKinship;
  final VoidCallback onCenterInTree;
  final VoidCallback onOpenFullProfile;

  const MobilePersonSheet({
    super.key,
    required this.person,
    required this.onInspectKinship,
    required this.onCenterInTree,
    required this.onOpenFullProfile,
  });

  static void show(
    BuildContext context, {
    required Person person,
    required VoidCallback onInspectKinship,
    required VoidCallback onCenterInTree,
    required VoidCallback onOpenFullProfile,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MobilePersonSheet(
        person: person,
        onInspectKinship: () {
          Navigator.pop(ctx);
          onInspectKinship();
        },
        onCenterInTree: () {
          Navigator.pop(ctx);
          onCenterInTree();
        },
        onOpenFullProfile: () {
          Navigator.pop(ctx);
          onOpenFullProfile();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);

    // Compute explicit genealogical summary
    final kinship = GenealogyHelper.getKinshipSummary(
      person,
      treeProvider.people,
      treeProvider.relationships,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131620) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: RoyalTheme.brightGold.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Top Profile Header
            Row(
              children: [
                MonogramMedallion(
                  person: person,
                  size: 58,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                        Text(
                          person.traditionalName!,
                          style: GoogleFonts.cinzel(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: RoyalTheme.brightGold,
                          ),
                          maxLines: 1,
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RoyalTheme.primaryGold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: RoyalTheme.primaryGold.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          kinship.lineageRole,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: RoyalTheme.brightGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Clan & Heritage Badges
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPill(
                    icon: Icons.layers_outlined,
                    label: 'Gen ${person.generationTier}',
                    color: RoyalTheme.brightGold,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPill(
                    icon: Icons.location_on_outlined,
                    label: person.villageOfOrigin ?? 'Bandjoun',
                    color: const Color(0xFF38BDF8),
                    isDark: isDark,
                  ),
                  if (person.clanTotem != null) ...[
                    const SizedBox(width: 8),
                    _buildPill(
                      icon: Icons.pets_outlined,
                      label: 'Totem: ${person.clanTotem}',
                      color: const Color(0xFFFB923C),
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(width: 8),
                  _buildPill(
                    icon: person.isLiving ? Icons.check_circle_outline : Icons.history_edu,
                    label: person.isLiving ? 'Living' : 'Ancestor',
                    color: person.isLiving ? const Color(0xFF10B981) : Colors.grey,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons Strip
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoyalTheme.brightGold,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.hub_outlined, size: 16),
                    label: const Text('Kinship', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: onInspectKinship,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: RoyalTheme.brightGold.withValues(alpha: 0.5)),
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.center_focus_strong_outlined, size: 16, color: RoyalTheme.brightGold),
                    label: const Text('Focus Tree', style: TextStyle(fontSize: 13)),
                    onPressed: onCenterInTree,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.badge_outlined, size: 16),
                    label: const Text('Profile', style: TextStyle(fontSize: 13)),
                    onPressed: onOpenFullProfile,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
