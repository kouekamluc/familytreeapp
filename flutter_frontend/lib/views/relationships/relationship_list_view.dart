import '../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/person.dart';
import '../../models/relationship.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/relationship_editor_dialog.dart';
import '../people/person_detail_view.dart';
import '../kinship/kinship_calculator_view.dart';
import '../../widgets/kkevo_ui.dart';
import '../../config/royal_theme.dart';

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
  final _search = TextEditingController();
  String _filter = 'all';
  int? _deleting;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(Relationship rel, Person first, Person second) async {
    final tree = context.read<TreeProvider>();
    final openedContext = tree.contextKey;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppText('Delete this connection?'),
        content: AppText(
          '${rel.label}: ${first.fullName} and ${second.fullName}. Both people will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AppText('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted || tree.contextKey != openedContext) return;
    setState(() => _deleting = rel.id);
    final ok = await tree.deleteRelationship(rel.id);
    if (!mounted) return;
    setState(() => _deleting = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          ok
              ? 'Connection deleted.'
              : tree.lastSaveError ??
                    'Unable to delete this connection. Try again.',
        ),
      ),
    );
  }

  void _openPerson(Person p) {
    if (widget.onNavigateToPerson != null) {
      widget.onNavigateToPerson!(p);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonDetailView(
            person: p,
            onNavigateToPerson: widget.onNavigateToPerson,
            onJumpToTree: widget.onJumpToTree,
          ),
        ),
      );
    }
  }

  Widget _person(Person p) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: MonogramMedallion(person: p, size: 40),
    title: Text(p.fullName),
    subtitle: p.traditionalName?.isNotEmpty == true
        ? Text(p.traditionalName!)
        : null,
    onTap: () => _openPerson(p),
  );

  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    final people = {for (final p in tree.people) p.id: p};
    final query = _search.text.trim().toLowerCase();
    final links = tree.relationships.where((r) {
      if (_filter == 'parents' && !r.isParent) return false;
      if (_filter == 'spouses' && !r.isSpousalLink) return false;
      if (_filter == 'siblings' && !r.isSibling) return false;
      final a = people[r.person1Id], b = people[r.person2Id];
      return a != null &&
          b != null &&
          (query.isEmpty ||
              '${a.fullName} ${a.traditionalName ?? ''} ${b.fullName} ${b.traditionalName ?? ''}'
                  .toLowerCase()
                  .contains(query));
    }).toList();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => tree.loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      'Every connection tells a story',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const AppText(
                      'Parents, children, partners… Give everyone a place.',
                    ),
                    const SizedBox(height: 20),
                    if (tree.canEditSelectedTree)
                      KkevoButton(
                        label: 'Add a connection',
                        icon: Icons.add_link_rounded,
                        onPressed: tree.people.length >= 2
                            ? () => RelationshipEditorDialog.show(context)
                            : null,
                      ),
                    const SizedBox(height: 10),
                    KkevoButton(
                      label: 'Explore a relationship',
                      secondary: true,
                      icon: Icons.route_rounded,
                      onPressed: tree.people.length >= 2
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(
                                    title: const AppText('Relationships'),
                                  ),
                                  body: const KinshipCalculatorView(),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.tr('Search a person'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: context.tr('Clear search'),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in {
                          'all': 'All',
                          'parents': 'Parents / children',
                          'spouses': 'Partnerships',
                          'siblings': 'Siblings',
                        }.entries)
                          ChoiceChip(
                            label: AppText(entry.value),
                            selected: _filter == entry.key,
                            onSelected: (_) =>
                                setState(() => _filter = entry.key),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (tree.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (links.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const KkevoIcon(
                        Icons.hub_outlined,
                        size: 64,
                        color: RoyalTheme.blue,
                      ),
                      const SizedBox(height: 16),
                      AppText(
                        tree.relationships.isEmpty
                            ? 'No family connections yet.'
                            : 'No connections match your search.',
                        textAlign: TextAlign.center,
                      ),
                      if (tree.people.length < 2)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: AppText(
                            'Add at least two people to create a connection.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (query.isNotEmpty || _filter != 'all')
                        TextButton(
                          onPressed: () {
                            _search.clear();
                            setState(() => _filter = 'all');
                          },
                          child: const AppText('Clear filters'),
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverList.builder(
                  itemCount: links.length,
                  itemBuilder: (_, i) {
                    final r = links[i],
                        a = people[r.person1Id]!,
                        b = people[r.person2Id]!;
                    final color = r.isSpousalLink
                        ? RoyalTheme.coral
                        : r.isSibling
                        ? RoyalTheme.violet
                        : r.relationshipType == 'ADOPTED'
                        ? RoyalTheme.blue
                        : RoyalTheme.green;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: KkevoPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                KkevoIcon(
                                  r.isSpousalLink
                                      ? Icons.favorite_outline_rounded
                                      : r.isSibling
                                      ? Icons.people_alt_outlined
                                      : Icons.account_tree_outlined,
                                  color: color,
                                  size: 38,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppText(
                                    r.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (tree.canEditSelectedTree)
                                  PopupMenuButton<String>(
                                    tooltip: context.tr('Connection options'),
                                    enabled: _deleting == null,
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        RelationshipEditorDialog.show(
                                          context,
                                          relationship: r,
                                        );
                                      }
                                      if (value == 'delete') _delete(r, a, b);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: AppText('Edit connection'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: AppText('Delete connection'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _person(a),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Icon(
                                r.isParent
                                    ? Icons.arrow_downward_rounded
                                    : Icons.link_rounded,
                                color: color,
                                size: 22,
                              ),
                            ),
                            _person(b),
                            if (r.startDate != null || r.endDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: AppText(
                                  '${r.startDate ?? 'Start not specified'} — ${r.endDate ?? 'End not specified'}',
                                ),
                              ),
                            if (r.notes?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(r.notes!),
                              ),
                            if (_deleting == r.id)
                              const LinearProgressIndicator(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
