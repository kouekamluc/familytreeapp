import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/node_action_sheet.dart';
import '../../widgets/tree_canvas.dart';

class TreeView extends StatelessWidget {
  final Function(Person)? onOpenKinshipForPerson;

  const TreeView({super.key, this.onOpenKinshipForPerson});

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Available generations for filter
    final tiers = treeProvider.people.map((p) => p.generationTier).toSet().toList()..sort();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Tree Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? RoyalTheme.surfaceDark : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Tree Title & Counts
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, color: RoyalTheme.brightGold),
                          const SizedBox(width: 8),
                          Text(
                            treeProvider.selectedTree?.name ?? 'Imperial Dynasty Tree',
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: RoyalTheme.primaryGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${treeProvider.filteredPeople.length} Members',
                              style: const TextStyle(fontSize: 11, color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Generation Tier Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All Tiers', style: TextStyle(fontSize: 12)),
                            selected: treeProvider.generationFilter == null,
                            selectedColor: RoyalTheme.primaryGold.withOpacity(0.3),
                            onSelected: (_) => treeProvider.setGenerationFilter(null),
                          ),
                          const SizedBox(width: 6),
                          for (final t in tiers)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('Gen $t', style: const TextStyle(fontSize: 12)),
                                selected: treeProvider.generationFilter == t,
                                selectedColor: RoyalTheme.primaryGold.withOpacity(0.3),
                                onSelected: (_) => treeProvider.setGenerationFilter(t),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Orientation Toggle
                    IconButton(
                      tooltip: treeProvider.orientation == TreeOrientation.vertical
                          ? 'Switch to Horizontal Pedigree'
                          : 'Switch to Vertical Dynasty',
                      icon: Icon(
                        treeProvider.orientation == TreeOrientation.vertical
                            ? Icons.swap_horiz_rounded
                            : Icons.swap_vert_rounded,
                        color: RoyalTheme.brightGold,
                      ),
                      onPressed: () => treeProvider.toggleOrientation(),
                    ),
                    // Reload Data
                    IconButton(
                      tooltip: 'Refresh Tree',
                      icon: const Icon(Icons.refresh, color: RoyalTheme.brightGold),
                      onPressed: () => treeProvider.loadData(),
                    ),
                  ],
                ),
              ),
              // Interactive Canvas
              Expanded(
                child: treeProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: RoyalTheme.brightGold),
                      )
                    : TreeCanvas(
                        people: treeProvider.filteredPeople,
                        relationships: treeProvider.relationships,
                        selectedPerson: treeProvider.selectedPerson,
                        orientation: treeProvider.orientation,
                        onSelectPerson: (person) {
                          treeProvider.selectPerson(person);
                        },
                      ),
              ),
            ],
          ),
          // Bottom Action Sheet for Selected Person
          if (treeProvider.selectedPerson != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: NodeActionSheet(
                    person: treeProvider.selectedPerson!,
                    onClose: () => treeProvider.selectPerson(null),
                    onNavigateToPerson: (p) => treeProvider.selectPerson(p),
                    onOpenKinship: (p) {
                      if (onOpenKinshipForPerson != null) {
                        onOpenKinshipForPerson!(p);
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
