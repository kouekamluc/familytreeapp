import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../utils/kinship_solver.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/royal_card.dart';

class PersonDetailView extends StatefulWidget {
  final Person person;
  final Function(Person)? onNavigateToPerson;
  final Function(Person)? onJumpToTree;
  final Function(Person)? onOpenKinship;

  const PersonDetailView({
    super.key,
    required this.person,
    this.onNavigateToPerson,
    this.onJumpToTree,
    this.onOpenKinship,
  });

  @override
  State<PersonDetailView> createState() => _PersonDetailViewState();
}

class _PersonDetailViewState extends State<PersonDetailView> {
  int? _testKinshipWithId;

  void _showEditPersonDialog(BuildContext context, Person person) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);

    final firstCtrl = TextEditingController(text: person.firstName);
    final lastCtrl = TextEditingController(text: person.lastName);
    final tradCtrl = TextEditingController(text: person.traditionalName ?? '');
    final villageCtrl = TextEditingController(text: person.villageOfOrigin ?? '');
    final totemCtrl = TextEditingController(text: person.clanTotem ?? '');
    final birthCtrl = TextEditingController(text: person.dateOfBirth ?? '');
    final deathCtrl = TextEditingController(text: person.dateOfDeath ?? '');
    final bioCtrl = TextEditingController(text: person.biography ?? '');
    String gender = person.gender;
    int tier = person.generationTier;
    bool isLiving = person.isLiving;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? RoyalTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: RoyalTheme.borderDark),
            ),
            title: Row(
              children: [
                const Icon(Icons.edit_note, color: RoyalTheme.brightGold),
                const SizedBox(width: 8),
                Text(
                  'Edit Dynasty Profile',
                  style: GoogleFonts.cinzel(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
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
                      decoration: const InputDecoration(labelText: 'Traditional Name / Customary Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: villageCtrl,
                      decoration: const InputDecoration(labelText: 'Village of Origin / Chefferie'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: totemCtrl,
                      decoration: const InputDecoration(labelText: 'Clan Totem / Emblème'),
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
                          items: [1, 2, 3, 4, 5, 6].map((t) => DropdownMenuItem(value: t, child: Text('Tier $t'))).toList(),
                          onChanged: (v) => setDlgState(() => tier = v ?? 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Is Living Member'),
                      value: isLiving,
                      activeThumbColor: RoyalTheme.brightGold,
                      onChanged: (v) => setDlgState(() => isLiving = v),
                    ),
                    TextField(
                      controller: birthCtrl,
                      decoration: const InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)', hintText: 'e.g. 1955-04-12'),
                    ),
                    if (!isLiving) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: deathCtrl,
                        decoration: const InputDecoration(labelText: 'Death Date (YYYY-MM-DD)'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Biography & Oral History Notes'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: RoyalTheme.brightGold),
                onPressed: () async {
                  if (firstCtrl.text.trim().isEmpty || lastCtrl.text.trim().isEmpty) return;

                  final patchData = <String, dynamic>{
                    'first_name': firstCtrl.text.trim(),
                    'last_name': lastCtrl.text.trim(),
                    'traditional_name': tradCtrl.text.trim(),
                    'village_of_origin': villageCtrl.text.trim(),
                    'clan_totem': totemCtrl.text.trim(),
                    'gender': gender,
                    'generation_tier': tier,
                    'is_living': isLiving,
                    'date_of_birth': birthCtrl.text.trim().isNotEmpty ? birthCtrl.text.trim() : null,
                    'date_of_death': (!isLiving && deathCtrl.text.trim().isNotEmpty) ? deathCtrl.text.trim() : null,
                    'biography': bioCtrl.text.trim(),
                  };

                  Navigator.pop(ctx);
                  final ok = await treeProvider.updatePerson(person.id, patchData);
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully.')),
                    );
                    setState(() {});
                  }
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddRelativeDialog(BuildContext context, Person currentPerson, {String defaultRole = 'child'}) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);

    String selectedRole = defaultRole; // 'father', 'mother', 'spouse', 'child'
    bool createNew = true;
    int? selectedExistingId;

    final spousesOfCurrent = treeProvider.getSpousesOf(currentPerson.id);
    int? selectedCoParentId;
    String allianceType = '💍 Mariage Coutumier & Dot Royale';

    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController(text: currentPerson.lastName);
    final tradCtrl = TextEditingController();
    final villageCtrl = TextEditingController(text: currentPerson.villageOfOrigin ?? '');
    final totemCtrl = TextEditingController(text: currentPerson.clanTotem ?? '');
    String gender = (defaultRole == 'father') ? 'M' : (defaultRole == 'mother' ? 'F' : 'M');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final availableExisting = treeProvider.people.where((p) => p.id != currentPerson.id).toList();

          return AlertDialog(
            backgroundColor: isDark ? RoyalTheme.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: RoyalTheme.borderDark),
            ),
            title: Row(
              children: [
                const Icon(Icons.group_add_outlined, color: RoyalTheme.brightGold),
                const SizedBox(width: 8),
                Text(
                  'Connect Relative',
                  style: GoogleFonts.cinzel(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connecting to ${currentPerson.fullName}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    // Relationship Role selector
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Relationship Role *'),
                      items: const [
                        DropdownMenuItem(value: 'father', child: Text('👨 Papa / Father')),
                        DropdownMenuItem(value: 'mother', child: Text('👩 Mama / Mother')),
                        DropdownMenuItem(value: 'spouse', child: Text('💍 Partner / Spouse')),
                        DropdownMenuItem(value: 'child', child: Text('👶 Child / Descendant')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDlgState(() {
                            selectedRole = v;
                            if (v == 'father') gender = 'M';
                            if (v == 'mother') gender = 'F';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Concession / Co-Parent selector when adding a child
                    if (selectedRole == 'child' && spousesOfCurrent.isNotEmpty) ...[
                      DropdownButtonFormField<int?>(
                        initialValue: selectedCoParentId,
                        decoration: InputDecoration(
                          labelText: currentPerson.isMale ? 'Mère / Concession Maternelle' : 'Père / Concession Paternelle',
                          helperText: 'Associer à une concession d\'épouse ou hors mariage',
                          helperStyle: const TextStyle(fontSize: 11),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('👶 Co-parentalité / Hors mariage'),
                          ),
                          ...spousesOfCurrent.map((s) => DropdownMenuItem<int?>(
                            value: s.id,
                            child: Text('👑 ${s.fullName} (${s.traditionalName ?? "Épouse"})'),
                          )),
                        ],
                        onChanged: (v) => setDlgState(() => selectedCoParentId = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Customary Alliance Type selector when adding a spouse
                    if (selectedRole == 'spouse') ...[
                      DropdownButtonFormField<String>(
                        initialValue: allianceType,
                        decoration: const InputDecoration(labelText: 'Nature de l\'Alliance Coutumière'),
                        items: const [
                          DropdownMenuItem(value: '💍 Mariage Coutumier & Dot Royale', child: Text('💍 Mariage Coutumier & Dot Royale')),
                          DropdownMenuItem(value: '🌿 Union Libre / Partenaire de Vie', child: Text('🌿 Union Libre / Partenaire de Vie')),
                          DropdownMenuItem(value: '👶 Co-Parentalité (Enfant hors mariage)', child: Text('👶 Co-Parentalité (Enfant hors mariage)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDlgState(() => allianceType = v);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Toggle: Create New vs Link Existing
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Enroll New Person')),
                            selected: createNew,
                            onSelected: (_) => setDlgState(() => createNew = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Link Existing Member')),
                            selected: !createNew,
                            onSelected: (_) => setDlgState(() => createNew = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (createNew) ...[
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
                        decoration: const InputDecoration(labelText: 'Traditional Name / Customary Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: villageCtrl,
                        decoration: const InputDecoration(labelText: 'Village of Origin'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: totemCtrl,
                        decoration: const InputDecoration(labelText: 'Clan Totem'),
                      ),
                      const SizedBox(height: 12),
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
                    ] else ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedExistingId,
                        decoration: const InputDecoration(labelText: 'Select Dynasty Member *'),
                        items: availableExisting.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.fullName} (${p.traditionalName ?? 'Gen ${p.generationTier}'})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setDlgState(() => selectedExistingId = v),
                      ),
                    ],
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
                  if (createNew) {
                    if (firstCtrl.text.trim().isEmpty || lastCtrl.text.trim().isEmpty) return;
                    int genTier = currentPerson.generationTier;
                    if (selectedRole == 'father' || selectedRole == 'mother') {
                      genTier = (currentPerson.generationTier > 1) ? currentPerson.generationTier - 1 : 1;
                    } else if (selectedRole == 'child') {
                      genTier = currentPerson.generationTier + 1;
                    }

                    final data = <String, dynamic>{
                      'first_name': firstCtrl.text.trim(),
                      'last_name': lastCtrl.text.trim(),
                      'traditional_name': tradCtrl.text.trim(),
                      'village_of_origin': villageCtrl.text.trim(),
                      'clan_totem': totemCtrl.text.trim(),
                      'gender': gender,
                      'generation_tier': genTier,
                      'is_living': true,
                    };

                    final created = await treeProvider.createRelative(
                      sourcePersonId: currentPerson.id,
                      role: selectedRole,
                      personData: data,
                    );
                    if (created != null) {
                      // Link co-parent if chosen
                      if (selectedRole == 'child' && selectedCoParentId != null) {
                        await treeProvider.addRelationship(selectedCoParentId!, created.id, 'PARENT');
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connected ${created.fullName} as $selectedRole.')),
                        );
                        setState(() {});
                      }
                    }
                  } else {
                    if (selectedExistingId == null) return;
                    final ok = await treeProvider.linkExistingRelative(
                      sourcePersonId: currentPerson.id,
                      targetPersonId: selectedExistingId!,
                      role: selectedRole,
                    );
                    if (ok) {
                      // Link co-parent if chosen
                      if (selectedRole == 'child' && selectedCoParentId != null) {
                        await treeProvider.addRelationship(selectedCoParentId!, selectedExistingId!, 'PARENT');
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lineage bond established successfully.')),
                        );
                        setState(() {});
                      }
                    }
                  }
                },
                child: const Text('Confirm Bond', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeletePerson(BuildContext context, Person person) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive / Remove Dynasty Member?'),
        content: Text('Are you sure you want to remove ${person.fullName} and associated relationships?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await treeProvider.deletePerson(person.id);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed ${person.fullName} from dynasty.')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final currentPerson = treeProvider.people.firstWhere(
      (p) => p.id == widget.person.id,
      orElse: () => widget.person,
    );

    final parents = treeProvider.getParentsOf(currentPerson.id);
    final father = parents.where((p) => p.isMale).firstOrNull;
    final mother = parents.where((p) => p.isFemale).firstOrNull;
    final spouses = treeProvider.getSpousesOf(currentPerson.id);
    final allSiblings = treeProvider.getSiblingsOf(currentPerson.id);
    final children = treeProvider.getChildrenOf(currentPerson.id);

    // African Customary Sibling Classification
    final myParentIds = parents.map((p) => p.id).toSet();
    final germainSiblings = <Person>[];
    final consanguinSiblings = <Person>[];
    final uterinSiblings = <Person>[];

    for (final sib in allSiblings) {
      final sibParents = treeProvider.getParentsOf(sib.id);
      final shared = sibParents.where((p) => myParentIds.contains(p.id)).toList();
      final hasSharedFather = shared.any((p) => p.isMale);
      final hasSharedMother = shared.any((p) => p.isFemale);

      if (hasSharedFather && hasSharedMother) {
        germainSiblings.add(sib);
      } else if (hasSharedFather) {
        consanguinSiblings.add(sib);
      } else if (hasSharedMother) {
        uterinSiblings.add(sib);
      } else {
        germainSiblings.add(sib);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RoyalTheme.brightGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          currentPerson.fullName.toUpperCase(),
          style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            tooltip: 'View in Tree',
            icon: const Icon(Icons.account_tree_outlined, color: RoyalTheme.brightGold),
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onJumpToTree != null) {
                widget.onJumpToTree!(currentPerson);
              }
            },
          ),
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, color: RoyalTheme.brightGold),
            onPressed: () => _showEditPersonDialog(context, currentPerson),
          ),
          IconButton(
            tooltip: 'Archive Member',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDeletePerson(context, currentPerson),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? RoyalTheme.surfaceDark : const Color(0xFFFBF8F2),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MonogramMedallion(person: currentPerson, size: 84, isSelected: true),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildBadge(
                                  currentPerson.isLiving ? '🌱 Living' : '🕊️ Ancestor',
                                  currentPerson.isLiving ? Colors.green : Colors.grey,
                                ),
                                if (currentPerson.traditionalName != null && currentPerson.traditionalName!.isNotEmpty)
                                  _buildBadge('👑 ${currentPerson.traditionalName}', RoyalTheme.brightGold),
                                if (currentPerson.clanTotem != null && currentPerson.clanTotem!.isNotEmpty)
                                  _buildBadge('Totem: ${currentPerson.clanTotem}', Colors.amber),
                                if (currentPerson.villageOfOrigin != null && currentPerson.villageOfOrigin!.isNotEmpty)
                                  _buildBadge('📍 ${currentPerson.villageOfOrigin}', Colors.blueGrey),
                                _buildBadge('Tier ${currentPerson.generationTier}', RoyalTheme.primaryGold),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentPerson.fullName,
                              style: GoogleFonts.cinzel(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentPerson.lifespanText.isNotEmpty
                                  ? currentPerson.lifespanText
                                  : (currentPerson.isLiving ? 'Present Dynasty Member' : 'Lifespan not recorded'),
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.account_tree, size: 15, color: Colors.black),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('View in Tree', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RoyalTheme.brightGold,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (widget.onJumpToTree != null) {
                              widget.onJumpToTree!(currentPerson);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.person_add_alt, size: 15, color: RoyalTheme.brightGold),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('+ Relative', style: TextStyle(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: RoyalTheme.brightGold),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showAddRelativeDialog(context, currentPerson),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 15, color: RoyalTheme.brightGold),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Kinship', style: TextStyle(color: RoyalTheme.brightGold, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: RoyalTheme.brightGold),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (widget.onOpenKinship != null) {
                              Navigator.of(context).pop();
                              widget.onOpenKinship!(currentPerson);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // MAIN CONTENT TABS / CARDS
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. FAMILY CONNECTIONS
                  _buildSectionTitle('👨‍👩‍👧‍👦 Family Connections', 'Direct parents, partner unions, siblings & descendants'),
                  const SizedBox(height: 12),
                  // Parents Grid
                  Row(
                    children: [
                      // Father
                      Expanded(
                        child: _buildRelativeCard(
                          roleTitle: '👨 Papa / Father',
                          person: father,
                          onAdd: () => _showAddRelativeDialog(context, currentPerson, defaultRole: 'father'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mother
                      Expanded(
                        child: _buildRelativeCard(
                          roleTitle: '👩 Mama / Mother',
                          person: mother,
                          onAdd: () => _showAddRelativeDialog(context, currentPerson, defaultRole: 'mother'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Spouse(s)
                  if (spouses.length <= 1)
                    _buildRelativeCard(
                      roleTitle: '💍 Conjoint(e) / Épouse',
                      person: spouses.isNotEmpty ? spouses.first : null,
                      onAdd: () => _showAddRelativeDialog(context, currentPerson, defaultRole: 'spouse'),
                    )
                  else
                    _buildKinshipListCard(
                      title: '💍 Épouses & Alliances Coutumières (Polygamie)',
                      members: spouses,
                      emptyText: 'Aucune épouse enregistrée.',
                      onAdd: () => _showAddRelativeDialog(context, currentPerson, defaultRole: 'spouse'),
                    ),
                  const SizedBox(height: 12),

                  // Siblings (Classified into Germains, Consanguins, Utérins)
                  if (consanguinSiblings.isNotEmpty || uterinSiblings.isNotEmpty) ...[
                    _buildKinshipListCard(
                      title: '👥 Frères & Sœurs Germains (Même Père, Même Mère)',
                      members: germainSiblings,
                      emptyText: 'Aucun frère ou sœur germain(e) enregistré(e).',
                    ),
                    if (consanguinSiblings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildKinshipListCard(
                        title: '👥 Frères & Sœurs Consanguins (Même Père, Concessions Différentes)',
                        members: consanguinSiblings,
                        emptyText: '',
                      ),
                    ],
                    if (uterinSiblings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildKinshipListCard(
                        title: '👥 Frères & Sœurs Utérins (Même Ventre / Maa Sacrée)',
                        members: uterinSiblings,
                        emptyText: '',
                      ),
                    ],
                  ] else ...[
                    _buildKinshipListCard(
                      title: '👥 Fratrie & Rameaux (Frères & Sœurs)',
                      members: allSiblings,
                      emptyText: 'Aucun frère ou sœur enregistré sous ces parents.',
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Children (Grouped by Maternal Concession for Polygamous Patriarchs)
                  if (spouses.length > 1) ...[
                    for (int i = 0; i < spouses.length; i++) ...[
                      Builder(builder: (ctx) {
                        final sp = spouses[i];
                        final spKids = children.where((c) => treeProvider.getParentsOf(c.id).any((p) => p.id == sp.id)).toList();
                        return Column(
                          children: [
                            _buildKinshipListCard(
                              title: '👶 Concession de ${sp.fullName} (${i == 0 ? "Grande Épouse" : "${i + 1}ème Épouse"})',
                              members: spKids,
                              emptyText: 'Aucun enfant enregistré pour cette concession.',
                              onAdd: () => _showAddRelativeDialog(context, currentPerson, defaultRole: 'child'),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                    ],
                    Builder(builder: (ctx) {
                      final unwedKids = children.where((c) => !spouses.any((sp) => treeProvider.getParentsOf(c.id).any((p) => p.id == sp.id))).toList();
                      if (unwedKids.isNotEmpty) {
                        return _buildKinshipListCard(
                          title: '👶 Enfants de Co-parentalité / Hors Mariage',
                          members: unwedKids,
                          emptyText: '',
                          onAdd: () => _showAddRelativeDialog(context, currentPerson, defaultRole: 'child'),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ] else ...[
                    _buildKinshipListCard(
                      title: '👶 Enfants & Descendants',
                      members: children,
                      emptyText: 'Aucun enfant enregistré pour ce membre.',
                      onAdd: () => _showAddRelativeDialog(context, currentPerson, defaultRole: 'child'),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 2. CULTURAL HERITAGE VAULT
                  _buildSectionTitle('🏺 Dynastic & Cultural Heritage Vault', 'Customary identity, clan roots & oral traditions'),
                  const SizedBox(height: 12),
                  RoyalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVaultRow('Customary Title', currentPerson.traditionalName ?? 'Not bestowed'),
                        const Divider(height: 20),
                        _buildVaultRow('Clan Totem & Heraldry', currentPerson.clanTotem ?? 'Unassigned'),
                        const Divider(height: 20),
                        _buildVaultRow('Village of Origin / Chefferie', currentPerson.villageOfOrigin ?? 'Ancestral grounds not recorded'),
                        const Divider(height: 20),
                        _buildVaultRow('Dynastic Tier', 'Tier ${currentPerson.generationTier}'),
                        if (currentPerson.biography != null && currentPerson.biography!.isNotEmpty) ...[
                          const Divider(height: 20),
                          Text(
                            'ORAL TRADITION & BIOGRAPHY',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentPerson.biography!,
                            style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. EMBEDDED KINSHIP TESTER
                  _buildSectionTitle('🧭 Instant Kinship Solver', 'Calculate exact relationship with any dynasty member'),
                  const SizedBox(height: 12),
                  _buildEmbeddedKinshipTester(currentPerson, treeProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildRelativeCard({
    required String roleTitle,
    required Person? person,
    required VoidCallback onAdd,
  }) {
    return RoyalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  roleTitle.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              if (person != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Linked', style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (person != null)
            InkWell(
              onTap: () {
                if (widget.onNavigateToPerson != null) {
                  widget.onNavigateToPerson!(person);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PersonDetailView(
                        person: person,
                        onNavigateToPerson: widget.onNavigateToPerson,
                        onJumpToTree: widget.onJumpToTree,
                        onOpenKinship: widget.onOpenKinship,
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  MonogramMedallion(person: person, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (person.traditionalName != null)
                          Text(
                            person.traditionalName!,
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: RoyalTheme.brightGold),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('None recorded', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 14, color: RoyalTheme.brightGold),
                  label: const Text('Add', style: TextStyle(color: RoyalTheme.brightGold, fontSize: 12)),
                  onPressed: onAdd,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKinshipListCard({
    required String title,
    required List<Person> members,
    required String emptyText,
    VoidCallback? onAdd,
  }) {
    return RoyalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$title (${members.length})'.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onAdd != null)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 14, color: RoyalTheme.brightGold),
                  label: const Text('Add', style: TextStyle(color: RoyalTheme.brightGold, fontSize: 12)),
                  onPressed: onAdd,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (members.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((m) {
                return ActionChip(
                  avatar: MonogramMedallion(person: m, size: 28),
                  label: Text(m.fullName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: RoyalTheme.surfaceDark,
                  side: const BorderSide(color: RoyalTheme.borderDark),
                  onPressed: () {
                    if (widget.onNavigateToPerson != null) {
                      widget.onNavigateToPerson!(m);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PersonDetailView(
                            person: m,
                            onNavigateToPerson: widget.onNavigateToPerson,
                            onJumpToTree: widget.onJumpToTree,
                            onOpenKinship: widget.onOpenKinship,
                          ),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            )
          else
            Text(emptyText, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildVaultRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildEmbeddedKinshipTester(Person currentPerson, TreeProvider treeProvider) {
    final otherPeople = treeProvider.people.where((p) => p.id != currentPerson.id).toList();
    final validSelectedId = otherPeople.any((p) => p.id == _testKinshipWithId) ? _testKinshipWithId : null;
    final targetPerson = otherPeople.where((p) => p.id == validSelectedId).firstOrNull;

    KinshipResult? result;
    if (targetPerson != null) {
      result = KinshipSolver.calculateKinship(
        personAId: currentPerson.id,
        personBId: targetPerson.id,
        people: treeProvider.people,
        relationships: treeProvider.relationships,
      );
    }

    return RoyalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculate how ${currentPerson.firstName} is connected to:',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: validSelectedId,
            hint: const Text('Choose a dynasty member...', overflow: TextOverflow.ellipsis),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            items: otherPeople.map((p) {
              return DropdownMenuItem(
                value: p.id,
                child: Text(
                  '${p.fullName} (${p.traditionalName ?? 'Gen ${p.generationTier}'})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _testKinshipWithId = v),
          ),
          if (result != null && targetPerson != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RoyalTheme.brightGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RoyalTheme.brightGold.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          result.title.toUpperCase(),
                          style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RoyalTheme.brightGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          result.relationship,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.culturalHonorific,
                    style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: RoyalTheme.lightGold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.summary,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
