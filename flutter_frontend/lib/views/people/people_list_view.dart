import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../utils/genealogy_helper.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/royal_button.dart';
import 'person_detail_view.dart';

class PeopleListView extends StatefulWidget {
  final Function(Person)? onSelectPersonForKinship;
  final Function(Person)? onJumpToTree;
  final Function(Person)? onOpenPersonDetail;

  const PeopleListView({
    super.key,
    this.onSelectPersonForKinship,
    this.onJumpToTree,
    this.onOpenPersonDetail,
  });

  @override
  State<PeopleListView> createState() => _PeopleListViewState();
}

class _PeopleListViewState extends State<PeopleListView> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedTier;
  String _statusFilter = 'all'; // 'all', 'living', 'ancestors'

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
            backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
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
                    decoration: const InputDecoration(labelText: 'Customary Title (e.g. Tadji, Ma, Fo)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: villageCtrl,
                    decoration: const InputDecoration(labelText: 'Village of Origin (e.g. Bandjoun)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: totemCtrl,
                    decoration: const InputDecoration(labelText: 'Clan Totem (e.g. Leopard 🐆)'),
                  ),
                  const SizedBox(height: 14),
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
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Gen 1 • Patriarchs & Ancestors')),
                          DropdownMenuItem(value: 2, child: Text('Gen 2 • Royal Elders & Keepers')),
                          DropdownMenuItem(value: 3, child: Text('Gen 3 • Living Descendants & Pillars')),
                          DropdownMenuItem(value: 4, child: Text('Gen 4 • 4th-Gen Youth & Princes')),
                        ],
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
              RoyalButton(
                label: 'Enroll to Dynasty',
                height: 40,
                fontSize: 13,
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
                    'is_living': true,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
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
    final allPeople = treeProvider.people;
    final relationships = treeProvider.relationships;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter people locally
    final query = _searchCtrl.text.toLowerCase().trim();
    final displayedPeople = allPeople.where((p) {
      if (query.isNotEmpty) {
        final matchesName = p.fullName.toLowerCase().contains(query);
        final matchesTrad = (p.traditionalName ?? '').toLowerCase().contains(query);
        final matchesTotem = (p.clanTotem ?? '').toLowerCase().contains(query);
        final matchesVillage = (p.villageOfOrigin ?? '').toLowerCase().contains(query);
        if (!matchesName && !matchesTrad && !matchesTotem && !matchesVillage) {
          return false;
        }
      }

      if (_statusFilter == 'living' && !p.isLiving) return false;
      if (_statusFilter == 'ancestors' && !p.isAncestor) return false;

      if (_selectedTier != null && p.generationTier != _selectedTier) return false;

      return true;
    }).toList();

    // Stats
    final totalCount = allPeople.length;
    final livingCount = allPeople.where((p) => p.isLiving).length;
    final ancestorCount = allPeople.where((p) => p.isAncestor).length;
    final allianceCount = relationships.where((r) => r.isSpouse).length;

    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0E14) : const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // 1. Top Header & Dynasty Stats Ribbon
          Container(
            padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, isMobile ? 14 : 20, isMobile ? 14 : 24, 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF11141E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, color: RoyalTheme.brightGold, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isMobile ? 'Family Registry' : 'Dynasty Family Registry',
                              style: GoogleFonts.cinzel(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoyalButton(
                      label: isMobile ? 'Enroll' : 'Enroll Member',
                      icon: const Icon(Icons.person_add_rounded, color: Colors.black, size: 15),
                      variant: RoyalButtonVariant.gold,
                      height: 36,
                      fontSize: 12,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                      onPressed: _showAddPersonDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats Counters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatBadge('👑 Total Dynasty', '$totalCount Members', isDark),
                      const SizedBox(width: 8),
                      _buildStatBadge('🌱 Living Pillars', '$livingCount Living', isDark),
                      const SizedBox(width: 8),
                      _buildStatBadge('🕊️ Ancestral Roots', '$ancestorCount Ancestors', isDark),
                      const SizedBox(width: 8),
                      _buildStatBadge('🏰 Generations', '4 Tiers', isDark),
                      const SizedBox(width: 8),
                      _buildStatBadge('💍 Sacred Alliances', '$allianceCount Marriages', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Search & Filter (Responsive layout)
                if (isMobile) ...[
                  // Mobile Search Field
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF181C28) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: query.isNotEmpty
                            ? RoyalTheme.brightGold
                            : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search by name, title, totem...',
                        hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                        prefixIcon: const Icon(Icons.search, size: 17, color: RoyalTheme.brightGold),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 15),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mobile Status Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('All ($totalCount)', style: const TextStyle(fontSize: 11)),
                          selected: _statusFilter == 'all',
                          selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                          onSelected: (_) => setState(() => _statusFilter = 'all'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text('Living ($livingCount)', style: const TextStyle(fontSize: 11)),
                          selected: _statusFilter == 'living',
                          selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                          onSelected: (_) => setState(() => _statusFilter = 'living'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text('Ancestors ($ancestorCount)', style: const TextStyle(fontSize: 11)),
                          selected: _statusFilter == 'ancestors',
                          selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                          onSelected: (_) => setState(() => _statusFilter = 'ancestors'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Desktop Search & Status Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF181C28) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: query.isNotEmpty
                                  ? RoyalTheme.brightGold
                                  : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                            ),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              hintText: 'Search relative by name, customary title, totem, or village...',
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
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text('All ($totalCount)', style: const TextStyle(fontSize: 11)),
                        selected: _statusFilter == 'all',
                        selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                        onSelected: (_) => setState(() => _statusFilter = 'all'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('Living ($livingCount)', style: const TextStyle(fontSize: 11)),
                        selected: _statusFilter == 'living',
                        selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                        onSelected: (_) => setState(() => _statusFilter = 'living'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text('Ancestors ($ancestorCount)', style: const TextStyle(fontSize: 11)),
                        selected: _statusFilter == 'ancestors',
                        selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.3),
                        onSelected: (_) => setState(() => _statusFilter = 'ancestors'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),

                // Generation Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Generations: ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('All Tiers', style: TextStyle(fontSize: 11)),
                        selected: _selectedTier == null,
                        selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.25),
                        onSelected: (_) => setState(() => _selectedTier = null),
                      ),
                      const SizedBox(width: 6),
                      for (int t = 1; t <= 4; t++) ...[
                        ChoiceChip(
                          label: Text('Gen $t', style: const TextStyle(fontSize: 11)),
                          selected: _selectedTier == t,
                          selectedColor: RoyalTheme.primaryGold.withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _selectedTier = t),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Members List with Explicit Relationships
          Expanded(
            child: displayedPeople.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No family relatives matching current filters.',
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
                    itemCount: displayedPeople.length,
                    itemBuilder: (context, idx) {
                      final person = displayedPeople[idx];
                      final kinship = GenealogyHelper.getKinshipSummary(person, allPeople, relationships);

                      if (isMobile) {
                        // --- MOBILE CARD LAYOUT ---
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131722) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: person.isAncestor
                                  ? RoyalTheme.brightGold.withValues(alpha: 0.5)
                                  : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                              width: person.isAncestor ? 1.4 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top: Medallion + Name + Customary Role
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      MonogramMedallion(person: person, size: 46),
                                      if (person.isAncestor)
                                        const Positioned(
                                          top: -6,
                                          right: -4,
                                          child: Text('👑', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          person.fullName,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                                          Text(
                                            person.traditionalName!,
                                            style: GoogleFonts.cinzel(
                                              fontSize: 11.5,
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF855B14),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: person.isAncestor
                                                ? const Color(0xFFB8860B).withValues(alpha: 0.25)
                                                : RoyalTheme.primaryGold.withValues(alpha: 0.18),
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
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Explicit Family Relationships Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF181C28) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? RoyalTheme.borderDark.withValues(alpha: 0.6) : RoyalTheme.borderLight,
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    _buildRelationSnippet(
                                      '👨 Father:',
                                      kinship.father != null
                                          ? kinship.father!.fullName
                                          : (person.generationTier == 1 ? 'Founding Patriarch' : 'Unrecorded'),
                                      isDark,
                                    ),
                                    _buildRelationSnippet(
                                      '👩 Mother:',
                                      kinship.mother != null
                                          ? kinship.mother!.fullName
                                          : (person.generationTier == 1 ? 'Founding Matriarch' : 'Unrecorded'),
                                      isDark,
                                    ),
                                    if (kinship.spouses.isNotEmpty)
                                      _buildRelationSnippet(
                                        '💍 Spouse:',
                                        '${kinship.spouses.map((s) => s.fullName).join(', ')} (Married)',
                                        isDark,
                                        isGold: true,
                                      ),
                                    if (kinship.allChildren.isNotEmpty)
                                      _buildRelationSnippet(
                                        '👶 Children:',
                                        '${kinship.allChildren.map((c) => c.firstName).join(', ')} (${kinship.allChildren.length})',
                                        isDark,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Customary Heritage Tags
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildTag('Gen ${person.generationTier}', RoyalTheme.brightGold),
                                  if (person.villageOfOrigin != null && person.villageOfOrigin!.isNotEmpty)
                                    _buildTag('📍 ${person.villageOfOrigin!}', Colors.blueGrey),
                                  if (person.clanTotem != null && person.clanTotem!.isNotEmpty)
                                    _buildTag('Totem: ${person.clanTotem!}', Colors.amber),
                                  if (person.isLiving)
                                    _buildTag('● Living', const Color(0xFF10B981))
                                  else if (person.lifespanText.isNotEmpty)
                                    _buildTag('🕊️ ${person.lifespanText}', Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Mobile Action Buttons Row
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.account_tree_rounded, size: 14, color: Colors.black),
                                      label: const Text('Show Tree', style: TextStyle(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: RoyalTheme.brightGold,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        if (widget.onJumpToTree != null) widget.onJumpToTree!(person);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.hub_rounded, size: 14, color: RoyalTheme.brightGold),
                                      label: const Text('Kinship', style: TextStyle(color: RoyalTheme.brightGold, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: RoyalTheme.brightGold),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        if (widget.onSelectPersonForKinship != null) widget.onSelectPersonForKinship!(person);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: Icon(Icons.badge_outlined, size: 14, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                      label: Text('Profile', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        if (widget.onOpenPersonDetail != null) {
                                          widget.onOpenPersonDetail!(person);
                                        } else {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => PersonDetailView(
                                                person: person,
                                                onJumpToTree: widget.onJumpToTree,
                                                onOpenKinship: widget.onSelectPersonForKinship,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      // --- DESKTOP CARD LAYOUT ---
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131722) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: person.isAncestor
                                ? RoyalTheme.brightGold.withValues(alpha: 0.5)
                                : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                            width: person.isAncestor ? 1.4 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Monogram Medallion
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                MonogramMedallion(person: person, size: 54),
                                if (person.isAncestor)
                                  const Positioned(
                                    top: -6,
                                    right: -4,
                                    child: Text('👑', style: TextStyle(fontSize: 13)),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Main Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name & Role Row
                                  Row(
                                    children: [
                                      Text(
                                        person.fullName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Explicit Lineage Role Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: person.isAncestor
                                              ? const Color(0xFFB8860B).withValues(alpha: 0.25)
                                              : RoyalTheme.primaryGold.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: RoyalTheme.brightGold.withValues(alpha: 0.5),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          '${kinship.lineageRole} • ${kinship.culturalRole}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: RoyalTheme.brightGold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Traditional Name
                                  if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        person.traditionalName!,
                                        style: GoogleFonts.cinzel(
                                          fontSize: 12.5,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF855B14),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 8),

                                  // EXPLICIT FAMILY RELATIONSHIPS ROW
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF181C28) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark ? RoyalTheme.borderDark.withValues(alpha: 0.6) : RoyalTheme.borderLight,
                                      ),
                                    ),
                                    child: Wrap(
                                      spacing: 16,
                                      runSpacing: 6,
                                      children: [
                                        // Father
                                        _buildRelationSnippet(
                                          '👨 Father:',
                                          kinship.father != null
                                              ? kinship.father!.fullName
                                              : (person.generationTier == 1 ? 'Founding Patriarch' : 'Unrecorded'),
                                          isDark,
                                        ),
                                        // Mother
                                        _buildRelationSnippet(
                                          '👩 Mother:',
                                          kinship.mother != null
                                              ? kinship.mother!.fullName
                                              : (person.generationTier == 1 ? 'Founding Matriarch' : 'Unrecorded'),
                                          isDark,
                                        ),
                                        // Spouse
                                        if (kinship.spouses.isNotEmpty)
                                          _buildRelationSnippet(
                                            '💍 Spouse:',
                                            '${kinship.spouses.map((s) => s.fullName).join(', ')} (Married)',
                                            isDark,
                                            isGold: true,
                                          ),
                                        // Children
                                        if (kinship.allChildren.isNotEmpty)
                                          _buildRelationSnippet(
                                            '👶 Children:',
                                            '${kinship.allChildren.map((c) => c.firstName).join(', ')} (${kinship.allChildren.length})',
                                            isDark,
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Customary Heritage Tags
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _buildTag('Gen ${person.generationTier}', RoyalTheme.brightGold),
                                      if (person.villageOfOrigin != null && person.villageOfOrigin!.isNotEmpty)
                                        _buildTag('📍 ${person.villageOfOrigin!}', Colors.blueGrey),
                                      if (person.clanTotem != null && person.clanTotem!.isNotEmpty)
                                        _buildTag('Totem: ${person.clanTotem!}', Colors.amber),
                                      if (person.isLiving)
                                        _buildTag('● Living', const Color(0xFF10B981))
                                      else if (person.lifespanText.isNotEmpty)
                                        _buildTag('🕊️ ${person.lifespanText}', Colors.grey),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Action Buttons Column (Desktop)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // View in Tree Button
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.account_tree_rounded, size: 16, color: Colors.black),
                                  label: const Text(
                                    'Show on Tree',
                                    style: TextStyle(color: Colors.black, fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: RoyalTheme.brightGold,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 2,
                                  ),
                                  onPressed: () {
                                    if (widget.onJumpToTree != null) {
                                      widget.onJumpToTree!(person);
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),

                                // Kinship Solver Button
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.hub_rounded, size: 15, color: RoyalTheme.brightGold),
                                  label: const Text(
                                    'Calculate Kinship',
                                    style: TextStyle(color: RoyalTheme.brightGold, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: RoyalTheme.brightGold, width: 1.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    if (widget.onSelectPersonForKinship != null) {
                                      widget.onSelectPersonForKinship!(person);
                                    }
                                  },
                                ),
                                const SizedBox(height: 6),

                                // Full Profile Button
                                TextButton.icon(
                                  icon: Icon(Icons.badge_outlined, size: 15, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                  label: Text(
                                    'Full Profile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                  onPressed: () {
                                    if (widget.onOpenPersonDetail != null) {
                                      widget.onOpenPersonDetail!(person);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PersonDetailView(
                                            person: person,
                                            onJumpToTree: widget.onJumpToTree,
                                            onOpenKinship: widget.onSelectPersonForKinship,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B26) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationSnippet(String label, String value, bool isDark, {bool isGold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isGold ? RoyalTheme.brightGold : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isGold ? RoyalTheme.brightGold : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
