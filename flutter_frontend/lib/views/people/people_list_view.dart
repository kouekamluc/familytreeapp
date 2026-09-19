import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/royal_card.dart';

class PeopleListView extends StatefulWidget {
  final Function(Person)? onSelectPersonForKinship;
  final Function(Person)? onJumpToTree;

  const PeopleListView({
    super.key,
    this.onSelectPersonForKinship,
    this.onJumpToTree,
  });

  @override
  State<PeopleListView> createState() => _PeopleListViewState();
}

class _PeopleListViewState extends State<PeopleListView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddPersonDialog() {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final tradCtrl = TextEditingController();
    final villageCtrl = TextEditingController();
    final totemCtrl = TextEditingController();
    String gender = 'M';
    int tier = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? RoyalTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: RoyalTheme.borderDark),
            ),
            title: Text(
              'Enroll Dynasty Member',
              style: GoogleFonts.cinzel(
                color: RoyalTheme.brightGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstCtrl,
                    decoration: const InputDecoration(labelText: 'First Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lastCtrl,
                    decoration: const InputDecoration(labelText: 'Last Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tradCtrl,
                    decoration: const InputDecoration(labelText: 'Traditional Name / Nom Coutumier'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: villageCtrl,
                    decoration: const InputDecoration(labelText: 'Village of Origin / Chefferie'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totemCtrl,
                    decoration: const InputDecoration(labelText: 'Clan Totem / Symbole'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Gender: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ChoiceChip(
                        label: const Text('Male'),
                        selected: gender == 'M',
                        onSelected: (_) => setDlgState(() => gender = 'M'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Female'),
                        selected: gender == 'F',
                        onSelected: (_) => setDlgState(() => gender = 'F'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Generation Tier: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: tier,
                        items: [1, 2, 3, 4, 5, 6].map((t) => DropdownMenuItem(value: t, child: Text('Tier $t'))).toList(),
                        onChanged: (val) {
                          if (val != null) setDlgState(() => tier = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: RoyalTheme.brightGold),
                onPressed: () async {
                  if (firstCtrl.text.trim().isEmpty || lastCtrl.text.trim().isEmpty) return;
                  final treeProv = Provider.of<TreeProvider>(context, listen: false);
                  await treeProv.addPerson({
                    'first_name': firstCtrl.text.trim(),
                    'last_name': lastCtrl.text.trim(),
                    'traditional_name': tradCtrl.text.trim(),
                    'village_of_origin': villageCtrl.text.trim(),
                    'clan_totem': totemCtrl.text.trim(),
                    'gender': gender,
                    'generation_tier': tier,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Enroll', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final people = treeProvider.filteredPeople;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header & Search
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
                    Text(
                      'Dynasty Registry',
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.black, size: 18),
                      label: const Text('Enroll Member', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: RoyalTheme.brightGold),
                      onPressed: _showAddPersonDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => treeProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search by full name, customary title, clan totem, or village...',
                    prefixIcon: const Icon(Icons.search, color: RoyalTheme.brightGold),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              treeProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                // Filter Tabs
                Row(
                  children: [
                    _buildTab('all', 'All Dynasty (${treeProvider.people.length})', treeProvider),
                    const SizedBox(width: 8),
                    _buildTab('living', 'Living (${treeProvider.people.where((p) => p.isLiving).length})', treeProvider),
                    const SizedBox(width: 8),
                    _buildTab('ancestors', 'Ancestors (${treeProvider.people.where((p) => p.isAncestor).length})', treeProvider),
                  ],
                ),
              ],
            ),
          ),
          // People Cards List
          Expanded(
            child: people.isEmpty
                ? Center(
                    child: Text(
                      'No members matching search query.',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: people.length,
                    itemBuilder: (context, idx) {
                      final person = people[idx];
                      final parents = treeProvider.getParentsOf(person.id);
                      final spouses = treeProvider.getSpousesOf(person.id);
                      final children = treeProvider.getChildrenOf(person.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RoyalCard(
                          onTap: () {
                            if (widget.onJumpToTree != null) {
                              treeProvider.selectPerson(person);
                              widget.onJumpToTree!(person);
                            }
                          },
                          child: Row(
                            children: [
                              MonogramMedallion(person: person, size: 58),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          person.fullName,
                                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        if (person.isAncestor)
                                          const Icon(Icons.shield, size: 16, color: RoyalTheme.brightGold),
                                      ],
                                    ),
                                    if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                                      Text(
                                        person.traditionalName!,
                                        style: GoogleFonts.cinzel(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: RoyalTheme.brightGold,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _buildBadge('Gen ${person.generationTier}', RoyalTheme.brightGold),
                                        if (person.clanTotem != null && person.clanTotem!.isNotEmpty)
                                          _buildBadge('Totem: ${person.clanTotem}', Colors.amber),
                                        if (person.villageOfOrigin != null && person.villageOfOrigin!.isNotEmpty)
                                          _buildBadge(person.villageOfOrigin!, Colors.blueGrey),
                                        if (person.lifespanText.isNotEmpty)
                                          _buildBadge(person.lifespanText, Colors.grey),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Relatives Summary
                                    Text(
                                      'Parents: ${parents.length}  •  Spouses: ${spouses.length}  •  Children: ${children.length}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                              // Kinship action button
                              IconButton(
                                icon: const Icon(Icons.hub_outlined, color: RoyalTheme.brightGold),
                                tooltip: 'Calculate Kinship with this person',
                                onPressed: () {
                                  if (widget.onSelectPersonForKinship != null) {
                                    widget.onSelectPersonForKinship!(person);
                                  }
                                },
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

  Widget _buildTab(String key, String label, TreeProvider prov) {
    final isSelected = prov.peopleFilterTab == key;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: RoyalTheme.primaryGold.withOpacity(0.3),
      onSelected: (_) => prov.setPeopleFilterTab(key),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
