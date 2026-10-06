import '../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../utils/kinship_solver.dart';
import '../../widgets/kkevo_ui.dart';
import '../../widgets/monogram_medallion.dart';
import '../people/person_detail_view.dart';

class KinshipCalculatorView extends StatefulWidget {
  final Person? initialPersonA, initialPersonB;
  const KinshipCalculatorView({
    super.key,
    this.initialPersonA,
    this.initialPersonB,
  });
  @override
  State<KinshipCalculatorView> createState() => _KinshipCalculatorViewState();
}

class _KinshipCalculatorViewState extends State<KinshipCalculatorView> {
  int? _a, _b;
  @override
  void initState() {
    super.initState();
    _a = widget.initialPersonA?.id;
    _b = widget.initialPersonB?.id;
  }

  @override
  void didUpdateWidget(covariant KinshipCalculatorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPersonA?.id != widget.initialPersonA?.id) {
      _a = widget.initialPersonA?.id;
    }
    if (oldWidget.initialPersonB?.id != widget.initialPersonB?.id) {
      _b = widget.initialPersonB?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>(), people = tree.people;
    if (tree.isLoading) return const Center(child: CircularProgressIndicator());
    if (people.length < 2) {
      return const Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KkevoIcon(Icons.route_rounded, size: 72, color: RoyalTheme.blue),
              SizedBox(height: 16),
              AppText(
                'Add at least two people and their connections to explore their relationship.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (!people.any((p) => p.id == _a)) _a = people.first.id;
    if (!people.any((p) => p.id == _b)) {
      _b = people.firstWhere((p) => p.id != _a).id;
    }
    final result = KinshipSolver.calculateKinship(
      personAId: _a!,
      personBId: _b!,
      people: people,
      relationships: tree.relationships,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'How are you connected?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const AppText(
                'Choose two people to discover the path that connects them.',
              ),
              const SizedBox(height: 24),
              KkevoPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _selector(
                      'From',
                      _a!,
                      people,
                      (value) => setState(() => _a = value),
                    ),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.swap_vert_rounded),
                        label: const AppText('Swap direction'),
                        onPressed: () => setState(() {
                          final previous = _a;
                          _a = _b;
                          _b = previous;
                        }),
                      ),
                    ),
                    _selector(
                      'To',
                      _b!,
                      people,
                      (value) => setState(() => _b = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              KkevoPanel(
                tint: result == null ? RoyalTheme.violet : RoyalTheme.green,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KkevoIcon(
                      result == null
                          ? Icons.explore_outlined
                          : Icons.route_rounded,
                      color: result == null
                          ? RoyalTheme.violet
                          : RoyalTheme.green,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      result?.title ?? 'A path still to discover',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      result?.summary ??
                          'No recorded connection joins these profiles. A missing parent or relative may complete the path.',
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 12),
                      AppText(result.description),
                      const SizedBox(height: 20),
                      for (var i = 0; i < result.path.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 18,
                              top: 4,
                              bottom: 4,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward_rounded,
                                  color: RoyalTheme.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppText(
                                    _edge(
                                      result.path[i - 1],
                                      result.path[i],
                                      tree,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: MonogramMedallion(
                            person: result.path[i],
                            size: 48,
                          ),
                          title: Text(result.path[i].fullName),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PersonDetailView(person: result.path[i]),
                            ),
                          ),
                        ),
                      ],
                      if (result.culturalHonorific.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: AppText(
                            'Traditional name: ${result.culturalHonorific}',
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const AppText(
                'The result follows recorded connections. Missing information or other branches may reveal different paths.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selector(
    String label,
    int id,
    List<Person> people,
    ValueChanged<int?> changed,
  ) => DropdownButtonFormField<int>(
    key: ValueKey('$label:$id'),
    initialValue: id,
    isExpanded: true,
    decoration: InputDecoration(labelText: context.tr(label)),
    items: people
        .map(
          (p) => DropdownMenuItem(
            value: p.id,
            child: Text(
              p.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: changed,
  );
  String _edge(Person first, Person second, TreeProvider tree) {
    final matches = tree.relationships.where(
      (r) =>
          (r.person1Id == first.id && r.person2Id == second.id) ||
          (r.person1Id == second.id && r.person2Id == first.id),
    );
    if (matches.isEmpty) return 'Family connection';
    final r = matches.first;
    if (r.isParent && r.person2Id == first.id) {
      return switch (r.relationshipType) {
        'ADOPTED' => 'To their adoptive parent',
        'STEP' => 'To their stepparent',
        _ => 'To their parent',
      };
    }
    return r.label;
  }
}
