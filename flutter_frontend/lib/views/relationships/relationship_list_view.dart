import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../models/relationship.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/royal_card.dart';
import '../people/person_detail_view.dart';

class RelationshipListView extends StatefulWidget {
  final Function(Person)? onNavigateToPerson;
  final Function(Person)? onJumpToTree;

  const RelationshipListView({
    super.key,
    this.onNavigateToPerson,
    this.onJumpToTree,
  });

  @override
  State<RelationshipListView> createState() => _RelationshipListViewState();
}

class _RelationshipListViewState extends State<RelationshipListView> {
  String _filter = 'all'; // 'all', 'spouses', 'parents'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = Provider.of<TreeProvider>(context, listen: false);
      if (tp.people.isEmpty && !tp.isLoading) {
        tp.loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddRelationshipDialog(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    final people = treeProvider.people;

    if (people.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least two dynasty members are required to establish a bond.')),
      );
      return;
    }

    int person1Id = people[0].id;
    int person2Id = people[1].id;
    String type = 'PARENT'; // 'PARENT', 'SPOUSE'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final p1 = people.where((p) => p.id == person1Id).firstOrNull;
          final p2 = people.where((p) => p.id == person2Id).firstOrNull;

          return AlertDialog(
            backgroundColor: isDark ? RoyalTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: RoyalTheme.borderDark),
            ),
            title: Row(
              children: [
                const Icon(Icons.link, color: RoyalTheme.brightGold),
                const SizedBox(width: 8),
                Text(
                  'Forge Lineage Bond',
                  style: GoogleFonts.cinzel(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Person 1
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: person1Id,
                      decoration: const InputDecoration(labelText: 'First Dynasty Member *'),
                      items: people.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.fullName} (${p.traditionalName ?? 'Tier ${p.generationTier}'})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDlgState(() {
                            person1Id = v;
                            if (person2Id == v) {
                              final others = people.where((p) => p.id != v);
                              if (others.isNotEmpty) {
                                person2Id = others.first.id;
                              }
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Type
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Bond Type *'),
                      items: const [
                        DropdownMenuItem(value: 'PARENT', child: Text('🌱 Parent → Child Lineage')),
                        DropdownMenuItem(value: 'SPOUSE', child: Text('💍 Spousal Matrimony')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDlgState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Person 2
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: person2Id,
                      decoration: const InputDecoration(labelText: 'Second Dynasty Member *'),
                      items: people.where((p) => p.id != person1Id).map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.fullName} (${p.traditionalName ?? 'Tier ${p.generationTier}'})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDlgState(() => person2Id = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    // Visual Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: RoyalTheme.brightGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p1?.firstName ?? 'Person 1', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              type == 'SPOUSE' ? Icons.favorite : Icons.arrow_forward,
                              size: 16,
                              color: RoyalTheme.brightGold,
                            ),
                          ),
                          Text(p2?.firstName ?? 'Person 2', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: RoyalTheme.brightGold),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await treeProvider.addRelationship(person1Id, person2Id, type);
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lineage bond established successfully.')),
                    );
                  }
                },
                child: const Text('Confirm Alliance', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteRelationship(BuildContext context, Relationship rel, Person p1, Person p2) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dissolve Lineage Bond?'),
        content: Text(
          rel.isSpouse
              ? 'Are you sure you want to dissolve the spousal union between ${p1.fullName} and ${p2.fullName}?'
              : 'Are you sure you want to remove the parent-child bond between ${p1.fullName} and ${p2.fullName}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await treeProvider.deleteRelationship(rel.id);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bond dissolved successfully.')),
                );
              }
            },
            child: const Text('Confirm Dissolution', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final allRels = treeProvider.relationships;
    final peopleMap = {for (var p in treeProvider.people) p.id: p};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter
    final filtered = allRels.where((r) {
      if (_filter == 'spouses' && !r.isSpouse) return false;
      if (_filter == 'parents' && !r.isParent) return false;

      final p1 = peopleMap[r.person1Id];
      final p2 = peopleMap[r.person2Id];
      if (p1 == null || p2 == null) return false;

      if (_searchCtrl.text.isNotEmpty) {
        final q = _searchCtrl.text.toLowerCase();
        final matchP1 = p1.fullName.toLowerCase().contains(q) || (p1.traditionalName ?? '').toLowerCase().contains(q);
        final matchP2 = p2.fullName.toLowerCase().contains(q) || (p2.traditionalName ?? '').toLowerCase().contains(q);
        if (!matchP1 && !matchP2) return false;
      }

      return true;
    }).toList();

    final spouseCount = allRels.where((r) => r.isSpouse).length;
    final parentCount = allRels.where((r) => r.isParent).length;

    return Scaffold(
      body: Column(
        children: [
          // Header & Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? RoyalTheme.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dynastic Alliances',
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Matrimonial unions & biological parentage lines',
                            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link, color: Colors.black, size: 16),
                      label: const Text('Forge Bond', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoyalTheme.brightGold,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _showAddRelationshipDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search Input
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Search by relative name or customary title...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, size: 18, color: RoyalTheme.brightGold),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Bonds (${allRels.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('spouses', '💍 Spouses ($spouseCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('parents', '🌱 Lineages ($parentCount)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Relationships List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No lineage bonds match the criteria.',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final rel = filtered[idx];
                      final p1 = peopleMap[rel.person1Id];
                      final p2 = peopleMap[rel.person2Id];
                      if (p1 == null || p2 == null) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RoyalCard(
                          child: Row(
                            children: [
                              // Person 1
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: () => _openPerson(p1),
                                  child: Row(
                                    children: [
                                      MonogramMedallion(person: p1, size: 44),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p1.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              p1.traditionalName ?? 'Tier ${p1.generationTier}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Center Badge
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: rel.isSpouse
                                        ? Colors.pinkAccent.withValues(alpha: 0.15)
                                        : RoyalTheme.brightGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: rel.isSpouse
                                          ? Colors.pinkAccent.withValues(alpha: 0.4)
                                          : RoyalTheme.brightGold.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        rel.isSpouse ? Icons.favorite : Icons.arrow_forward,
                                        size: 14,
                                        color: rel.isSpouse ? Colors.pinkAccent : RoyalTheme.brightGold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        rel.isSpouse ? 'SPOUSE' : 'PARENT OF',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: rel.isSpouse ? Colors.pinkAccent : RoyalTheme.brightGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Person 2
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: () => _openPerson(p2),
                                  child: Row(
                                    children: [
                                      MonogramMedallion(person: p2, size: 44),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p2.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              p2.traditionalName ?? 'Tier ${p2.generationTier}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Delete Action
                              IconButton(
                                icon: const Icon(Icons.link_off, size: 20, color: Colors.redAccent),
                                tooltip: 'Dissolve Bond',
                                onPressed: () => _confirmDeleteRelationship(context, rel, p1, p2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openPerson(Person person) {
    if (widget.onNavigateToPerson != null) {
      widget.onNavigateToPerson!(person);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonDetailView(
            person: person,
            onNavigateToPerson: widget.onNavigateToPerson,
            onJumpToTree: widget.onJumpToTree,
          ),
        ),
      );
    }
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : null,
        ),
      ),
      selected: isSelected,
      selectedColor: RoyalTheme.brightGold,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
