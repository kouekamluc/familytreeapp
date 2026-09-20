import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/mobile_person_sheet.dart';
import '../../widgets/node_action_sheet.dart';
import '../../widgets/tree_canvas.dart';

class TreeView extends StatefulWidget {
  final Function(Person)? onOpenKinshipForPerson;
  final Function(Person)? onOpenPersonDetail;

  const TreeView({
    super.key,
    this.onOpenKinshipForPerson,
    this.onOpenPersonDetail,
  });

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TreeLayoutMode _layoutMode = TreeLayoutMode.pedigree;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final treeProvider = Provider.of<TreeProvider>(context, listen: false);
      if (treeProvider.people.isEmpty && !treeProvider.isLoading) {
        treeProvider.loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Available generations for filter
    final tiers = treeProvider.people.map((p) => p.generationTier).toSet().toList()..sort();

    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Tree Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF11141E) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                    ),
                  ),
                ),
                child: isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, color: RoyalTheme.brightGold, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  treeProvider.selectedTree?.name ?? 'Kkevo Royal Lineage Tree',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RoyalTheme.primaryGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${treeProvider.filteredPeople.length} Members',
                                  style: const TextStyle(fontSize: 10.5, color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh Tree',
                                icon: const Icon(Icons.refresh, color: RoyalTheme.brightGold, size: 18),
                                onPressed: () => treeProvider.loadData(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Royal Scope Selector (Extended Dynasty vs Immediate Family)
                          Container(
                            height: 32,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161A26) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: RoyalTheme.brightGold.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => treeProvider.setTreeScope(TreeScope.extendedDynasty),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: treeProvider.treeScope == TreeScope.extendedDynasty
                                            ? RoyalTheme.brightGold
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '👑 Dynastie Complète',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: treeProvider.treeScope == TreeScope.extendedDynasty
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: treeProvider.treeScope == TreeScope.extendedDynasty
                                              ? Colors.black
                                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => treeProvider.setTreeScope(TreeScope.immediateFamily),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: treeProvider.treeScope == TreeScope.immediateFamily
                                            ? RoyalTheme.brightGold
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '🏡 Famille Proche',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: treeProvider.treeScope == TreeScope.immediateFamily
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: treeProvider.treeScope == TreeScope.immediateFamily
                                              ? Colors.black
                                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All Tiers', style: TextStyle(fontSize: 11)),
                                  selected: treeProvider.generationFilter == null,
                                  selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                                  onSelected: (_) => treeProvider.setGenerationFilter(null),
                                ),
                                const SizedBox(width: 6),
                                for (final t in tiers)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('Gen $t', style: const TextStyle(fontSize: 11)),
                                      selected: treeProvider.generationFilter == t,
                                      selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                                      onSelected: (_) => treeProvider.setGenerationFilter(t),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Tree Title & Counts
                          Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, color: RoyalTheme.brightGold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                treeProvider.selectedTree?.name ?? 'Kkevo Royal Lineage Tree',
                                style: GoogleFonts.cinzel(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RoyalTheme.primaryGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '${treeProvider.filteredPeople.length} Members',
                                  style: const TextStyle(fontSize: 11, color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Search Relative Input
                          Container(
                            width: 220,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF181C28) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _searchQuery.isNotEmpty
                                    ? RoyalTheme.brightGold
                                    : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                                width: _searchQuery.isNotEmpty ? 1.4 : 1.0,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search relative (e.g. Grace)...',
                                hintStyle: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                                prefixIcon: const Icon(Icons.search, size: 16, color: RoyalTheme.brightGold),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 14),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 9),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Layout Mode Switcher (Pedigree vs Generational Tiers)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF181C28) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLayoutButton(
                                  icon: Icons.account_tree,
                                  label: 'Pedigree',
                                  isActive: _layoutMode == TreeLayoutMode.pedigree,
                                  onTap: () => setState(() => _layoutMode = TreeLayoutMode.pedigree),
                                  isDark: isDark,
                                ),
                                _buildLayoutButton(
                                  icon: Icons.view_headline_rounded,
                                  label: 'Tiers',
                                  isActive: _layoutMode == TreeLayoutMode.tiered,
                                  onTap: () => setState(() => _layoutMode = TreeLayoutMode.tiered),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Generation Tier Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All Tiers', style: TextStyle(fontSize: 11)),
                                  selected: treeProvider.generationFilter == null,
                                  selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                                  onSelected: (_) => treeProvider.setGenerationFilter(null),
                                ),
                                const SizedBox(width: 6),
                                for (final t in tiers)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text('Gen $t', style: const TextStyle(fontSize: 11)),
                                      selected: treeProvider.generationFilter == t,
                                      selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                                      onSelected: (_) => treeProvider.setGenerationFilter(t),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Reload Data
                          IconButton(
                            tooltip: 'Refresh Tree',
                            icon: const Icon(Icons.refresh, color: RoyalTheme.brightGold, size: 20),
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
                        people: treeProvider.activeTreePeople,
                        relationships: treeProvider.relationships,
                        selectedPerson: treeProvider.selectedPerson,
                        layoutMode: _layoutMode,
                        searchQuery: _searchQuery,
                        orientation: treeProvider.orientation,
                        onSelectPerson: (person) {
                          treeProvider.selectPerson(person);
                          if (isMobile) {
                            MobilePersonSheet.show(
                              context,
                              person: person,
                              onInspectKinship: () {
                                if (widget.onOpenKinshipForPerson != null) {
                                  widget.onOpenKinshipForPerson!(person);
                                }
                              },
                              onCenterInTree: () {
                                treeProvider.selectPerson(person);
                              },
                              onOpenFullProfile: () {
                                if (widget.onOpenPersonDetail != null) {
                                  widget.onOpenPersonDetail!(person);
                                }
                              },
                            );
                          }
                        },
                      ),
              ),
            ],
          ),

          // Right Inspector Drawer for Selected Person (Desktop Only - Mobile uses native MobilePersonSheet)
          if (!isMobile && treeProvider.selectedPerson != null)
            Positioned(
              top: 16,
              right: 16,
              bottom: 16,
              width: 380,
              child: Material(
                color: Colors.transparent,
                child: NodeActionSheet(
                  person: treeProvider.selectedPerson!,
                  onClose: () => treeProvider.selectPerson(null),
                  onNavigateToPerson: (p) => treeProvider.selectPerson(p),
                  onOpenPersonDetail: (p) {
                    if (widget.onOpenPersonDetail != null) {
                      widget.onOpenPersonDetail!(p);
                    }
                  },
                  onOpenKinship: (p) {
                    if (widget.onOpenKinshipForPerson != null) {
                      widget.onOpenKinshipForPerson!(p);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayoutButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? RoyalTheme.primaryGold.withValues(alpha: 0.25) : RoyalTheme.primaryGold.withValues(alpha: 0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.6), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? RoyalTheme.brightGold : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? RoyalTheme.brightGold : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
