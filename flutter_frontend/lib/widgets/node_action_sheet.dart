import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import '../utils/genealogy_helper.dart';
import 'monogram_medallion.dart';

class NodeActionSheet extends StatelessWidget {
  final Person person;
  final VoidCallback? onClose;
  final Function(Person)? onNavigateToPerson;
  final Function(Person)? onOpenKinship;
  final Function(Person)? onOpenPersonDetail;

  const NodeActionSheet({
    super.key,
    required this.person,
    this.onClose,
    this.onNavigateToPerson,
    this.onOpenKinship,
    this.onOpenPersonDetail,
  });

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute explicit genealogical summary
    final kinship = GenealogyHelper.getKinshipSummary(
      person,
      treeProvider.people,
      treeProvider.relationships,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? RoyalTheme.brightGold.withValues(alpha: 0.4) : RoyalTheme.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: RoyalTheme.brightGold.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1F2C), const Color(0xFF11141E)]
                      : [const Color(0xFFFBF8EE), const Color(0xFFF5EFE0)],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonogramMedallion(
                    person: person,
                    size: 58,
                    isSelected: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                person.fullName,
                                style: GoogleFonts.cinzel(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (person.isAncestor)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.shield, size: 16, color: RoyalTheme.brightGold),
                              ),
                          ],
                        ),
                        // Explicit Lineage Role Badge
                        Container(
                          margin: const EdgeInsets.only(top: 3, bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: RoyalTheme.primaryGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: RoyalTheme.brightGold.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${kinship.lineageRole} • ${kinship.culturalRole}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: RoyalTheme.brightGold,
                            ),
                          ),
                        ),
                        if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              person.traditionalName!,
                              style: GoogleFonts.cinzel(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF855B14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.grey,
                      tooltip: 'Close Inspector',
                      onPressed: onClose,
                    ),
                ],
              ),
            ),

            // 2. Scrollable Content with Explicit Relationships
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Generation & Cultural Meta Pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildPill('Gen ${person.generationTier}', RoyalTheme.brightGold),
                      if (person.clanTotem != null && person.clanTotem!.isNotEmpty)
                        _buildPill('Totem: ${person.clanTotem}', Colors.amber),
                      if (person.villageOfOrigin != null && person.villageOfOrigin!.isNotEmpty)
                        _buildPill(person.villageOfOrigin!, Colors.blueGrey),
                      if (person.isLiving)
                        _buildPill('Living', const Color(0xFF10B981))
                      else if (person.lifespanText.isNotEmpty)
                        _buildPill(person.lifespanText, Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Oral Biography if present
                  if (person.biography != null && person.biography!.isNotEmpty) ...[
                    Text(
                      'ORAL RECORD & BIOGRAPHY',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: RoyalTheme.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F121A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                        ),
                      ),
                      child: Text(
                        person.biography!,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // EXPLICIT RELATIONSHIPS SECTION
                  Text(
                    'GENEALOGICAL RELATIONSHIPS',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: RoyalTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Father & Mother
                  if (kinship.father != null)
                    _buildExplicitRelationRow('👨 Father', kinship.father!, isDark)
                  else
                    _buildStaticInfoRow('👨 Father', 'Founding Patriarch / Lineage Root', isDark),

                  if (kinship.mother != null)
                    _buildExplicitRelationRow('👩 Mother', kinship.mother!, isDark)
                  else if (person.generationTier > 1)
                    _buildStaticInfoRow('👩 Mother', 'Unrecorded in lineage archive', isDark),

                  // Spouse / Alliances
                  if (kinship.spouses.isNotEmpty)
                    for (final sp in kinship.spouses)
                      _buildExplicitRelationRow('💍 Spouse (Married)', sp, isDark)
                  else
                    _buildStaticInfoRow('💍 Alliance', 'Single / Unallied', isDark),

                  // Children
                  if (kinship.allChildren.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildCircleSection('Children (${kinship.allChildren.length})', kinship.allChildren, Icons.child_care_outlined, isDark),
                  ],

                  // Siblings
                  if (kinship.allSiblings.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildCircleSection('Siblings (${kinship.allSiblings.length})', kinship.allSiblings, Icons.people_outline, isDark),
                  ],
                ],
              ),
            ),

            // 3. Action Shortcuts Bottom Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF10131B) : const Color(0xFFF1F5F9),
                border: Border(
                  top: BorderSide(
                    color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person, color: Colors.black, size: 15),
                      label: const Text(
                        'Full Profile',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoyalTheme.brightGold,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (onOpenPersonDetail != null) {
                          onOpenPersonDetail!(person);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome, color: RoyalTheme.brightGold, size: 15),
                      label: const Text(
                        'Kinship Solver',
                        style: TextStyle(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: RoyalTheme.brightGold),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplicitRelationRow(String roleLabel, Person relPerson, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          if (onNavigateToPerson != null) {
            onNavigateToPerson!(relPerson);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171B26) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
            ),
          ),
          child: Row(
            children: [
              Text(
                roleLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
              ),
              const Spacer(),
              MonogramMedallion(person: relPerson, size: 22),
              const SizedBox(width: 6),
              Text(
                relPerson.fullName,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticInfoRow(String roleLabel, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF11141E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? RoyalTheme.borderDark.withValues(alpha: 0.5) : RoyalTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            Text(
              roleLabel,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildCircleSection(String title, List<Person> members, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: RoyalTheme.primaryGold),
            const SizedBox(width: 5),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: RoyalTheme.primaryGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: members.map((m) {
            return InkWell(
              onTap: () {
                if (onNavigateToPerson != null) {
                  onNavigateToPerson!(m);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191D28) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MonogramMedallion(person: m, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      m.fullName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
