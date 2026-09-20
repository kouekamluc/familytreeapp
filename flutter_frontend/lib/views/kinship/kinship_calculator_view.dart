import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../utils/kinship_solver.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/royal_card.dart';

class KinshipCalculatorView extends StatefulWidget {
  final Person? initialPersonA;
  final Person? initialPersonB;

  const KinshipCalculatorView({
    super.key,
    this.initialPersonA,
    this.initialPersonB,
  });

  @override
  State<KinshipCalculatorView> createState() => _KinshipCalculatorViewState();
}

class _KinshipCalculatorViewState extends State<KinshipCalculatorView> {
  int? _personAId;
  int? _personBId;

  @override
  void initState() {
    super.initState();
    _personAId = widget.initialPersonA?.id;
    _personBId = widget.initialPersonB?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = Provider.of<TreeProvider>(context, listen: false);
      if (tp.people.isEmpty && !tp.isLoading) {
        tp.loadData();
      }
    });
  }

  @override
  void didUpdateWidget(covariant KinshipCalculatorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPersonA != null && widget.initialPersonA?.id != oldWidget.initialPersonA?.id) {
      setState(() {
        _personAId = widget.initialPersonA!.id;
      });
    }
    if (widget.initialPersonB != null && widget.initialPersonB?.id != oldWidget.initialPersonB?.id) {
      setState(() {
        _personBId = widget.initialPersonB!.id;
      });
    }
  }

  void _swap() {
    setState(() {
      final temp = _personAId;
      _personAId = _personBId;
      _personBId = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final people = treeProvider.people;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

    // Set initial defaults if unselected
    if (_personAId == null && people.isNotEmpty) {
      _personAId = people.first.id;
    }
    if (_personBId == null && people.length > 1) {
      _personBId = people[1].id;
    }

    KinshipResult? result;
    if (_personAId != null && _personBId != null && people.isNotEmpty) {
      final validA = people.any((p) => p.id == _personAId) ? _personAId! : people.first.id;
      final validB = people.any((p) => p.id == _personBId) ? _personBId! : (people.length > 1 ? people[1].id : people.first.id);
      result = KinshipSolver.calculateKinship(
        personAId: validA,
        personBId: validB,
        people: people,
        relationships: treeProvider.relationships,
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.hub_outlined, color: RoyalTheme.brightGold, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Imperial Kinship Solver',
                        style: GoogleFonts.cinzel(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Solve biological, spousal, and ancestral kinship paths between any two dynasty members.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 18),
                // Selector Card
                RoyalCard(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    children: [
                      if (isMobile) ...[
                        _buildPersonDropdown(
                          label: 'Origin Member (Person A)',
                          selectedId: _personAId,
                          people: people,
                          onChanged: (id) => setState(() => _personAId = id),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Center(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.swap_vert_rounded, color: RoyalTheme.brightGold, size: 20),
                              label: const Text('Invert Perspective', style: TextStyle(color: RoyalTheme.brightGold, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: RoyalTheme.brightGold.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _swap,
                            ),
                          ),
                        ),
                        _buildPersonDropdown(
                          label: 'Target Relative (Person B)',
                          selectedId: _personBId,
                          people: people,
                          onChanged: (id) => setState(() => _personBId = id),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildPersonDropdown(
                                label: 'Origin Member (Person A)',
                                selectedId: _personAId,
                                people: people,
                                onChanged: (id) => setState(() => _personAId = id),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: IconButton(
                                icon: const Icon(Icons.swap_horiz_rounded, color: RoyalTheme.brightGold, size: 24),
                                tooltip: 'Swap Perspective',
                                onPressed: _swap,
                              ),
                            ),
                            Expanded(
                              child: _buildPersonDropdown(
                                label: 'Target Relative (Person B)',
                                selectedId: _personBId,
                                people: people,
                                onChanged: (id) => setState(() => _personBId = id),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Quick Presets
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          const Text(
                            'Quick Demo Presets: ',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          _buildPresetChip('First Pair', people.isNotEmpty ? people.first.id : null, people.length > 1 ? people[1].id : null),
                          if (people.length >= 4)
                            _buildPresetChip('Generational Jump', people.first.id, people.last.id),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Kinship Result Card
                if (result != null) _buildResultSection(result, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonDropdown({
    required String label,
    required int? selectedId,
    required List<Person> people,
    required Function(int?) onChanged,
  }) {
    final validSelectedId = people.any((p) => p.id == selectedId)
        ? selectedId
        : (people.isNotEmpty ? people.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RoyalTheme.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: validSelectedId,
              items: people.map((p) {
                return DropdownMenuItem<int>(
                  value: p.id,
                  child: Row(
                    children: [
                      MonogramMedallion(person: p, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${p.fullName} (${p.traditionalName ?? "Gen ${p.generationTier}"})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, int? p1, int? p2) {
    if (p1 == null || p2 == null) return const SizedBox.shrink();
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: RoyalTheme.primaryGold.withValues(alpha: 0.15),
      side: const BorderSide(color: RoyalTheme.borderDark),
      onPressed: () {
        setState(() {
          _personAId = p1;
          _personBId = p2;
        });
      },
    );
  }

  Widget _buildResultSection(KinshipResult res, bool isDark) {
    return RoyalCard(
      padding: const EdgeInsets.all(28),
      isSelected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Honorific Banner
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: RoyalTheme.primaryGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RoyalTheme.brightGold),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: RoyalTheme.brightGold, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        res.culturalHonorific.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: RoyalTheme.brightGold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.generationDifference == 0
                      ? 'Same Generation'
                      : (res.generationDifference > 0
                          ? '+${res.generationDifference} Gen Above'
                          : '${res.generationDifference} Gen Below'),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            res.title,
            style: GoogleFonts.cinzel(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? RoyalTheme.lightGold : const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            res.summary,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: RoyalTheme.brightGold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            res.description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: RoyalTheme.borderDark),
          const SizedBox(height: 16),
          // Bloodline Step Path Ribbon
          Text(
            'BLOODLINE STEP PATH RIBBON (${res.path.length} NODES)',
            style: GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: RoyalTheme.brightGold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < res.path.length; i++) ...[
                  _buildPathNode(res.path[i], i == 0, i == res.path.length - 1),
                  if (i < res.path.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Container(width: 24, height: 2, color: RoyalTheme.brightGold),
                          const Icon(Icons.chevron_right, color: RoyalTheme.brightGold, size: 20),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathNode(Person person, bool isOrigin, bool isTarget) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isOrigin || isTarget)
            ? RoyalTheme.primaryGold.withValues(alpha: 0.15)
            : RoyalTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isOrigin || isTarget) ? RoyalTheme.brightGold : RoyalTheme.borderDark,
          width: (isOrigin || isTarget) ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          MonogramMedallion(person: person, size: 40),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                isOrigin
                    ? 'Origin (A)'
                    : (isTarget ? 'Target (B)' : 'Gen ${person.generationTier} Connector'),
                style: TextStyle(
                  fontSize: 11,
                  color: (isOrigin || isTarget) ? RoyalTheme.brightGold : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
