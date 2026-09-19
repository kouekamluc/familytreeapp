import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import 'monogram_medallion.dart';

class NodeActionSheet extends StatelessWidget {
  final Person person;
  final VoidCallback? onClose;
  final Function(Person)? onNavigateToPerson;
  final Function(Person)? onOpenKinship;

  const NodeActionSheet({
    super.key,
    required this.person,
    this.onClose,
    this.onNavigateToPerson,
    this.onOpenKinship,
  });

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final parents = treeProvider.getParentsOf(person.id);
    final spouses = treeProvider.getSpousesOf(person.id);
    final siblings = treeProvider.getSiblingsOf(person.id);
    final children = treeProvider.getChildrenOf(person.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: isDark ? RoyalTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: RoyalTheme.primaryGold.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                MonogramMedallion(person: person, size: 68, isSelected: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                        ),
                      ),
                      if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                        Text(
                          person.traditionalName!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: RoyalTheme.brightGold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildPill('Tier ${person.generationTier}', RoyalTheme.brightGold),
                          if (person.clanTotem != null && person.clanTotem!.isNotEmpty)
                            _buildPill('Totem: ${person.clanTotem}', Colors.amber),
                          if (person.villageOfOrigin != null && person.villageOfOrigin!.isNotEmpty)
                            _buildPill(person.villageOfOrigin!, Colors.blueGrey),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: RoyalTheme.borderDark),
          // Immediate Kinship Circle
          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _buildCircleSection('Parents (${parents.length})', parents, Icons.nature_people_outlined),
                _buildCircleSection('Spouses (${spouses.length})', spouses, Icons.favorite_border),
                _buildCircleSection('Siblings (${siblings.length})', siblings, Icons.people_outline),
                _buildCircleSection('Children (${children.length})', children, Icons.child_care_outlined),
                const SizedBox(height: 12),
                // Action shortcut buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                        label: const Text('Calculate Kinship', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoyalTheme.brightGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          if (onOpenKinship != null) {
                            onOpenKinship!(person);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildCircleSection(String title, List<Person> members, IconData icon) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: RoyalTheme.primaryGold),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: RoyalTheme.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final m = members[idx];
                return ActionChip(
                  avatar: MonogramMedallion(person: m, size: 28),
                  label: Text(m.fullName),
                  backgroundColor: RoyalTheme.cardDark,
                  side: const BorderSide(color: RoyalTheme.borderDark),
                  onPressed: () {
                    if (onNavigateToPerson != null) {
                      onNavigateToPerson!(m);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
