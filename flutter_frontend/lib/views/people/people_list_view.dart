import '../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/person_editor_dialog.dart';
import '../../widgets/tree_manager_sheet.dart';
import '../../widgets/kkevo_ui.dart';
import '../../config/royal_theme.dart';
import 'person_detail_view.dart';

class PeopleListView extends StatefulWidget {
  final Function(Person)? onSelectPersonForKinship,
      onJumpToTree,
      onOpenPersonDetail;
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
  final _search = TextEditingController();
  String _status = 'all';
  int? _tier;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _status = 'all';
      _tier = null;
    });
  }

  void _open(Person p) {
    if (widget.onOpenPersonDetail != null) {
      widget.onOpenPersonDetail!(p);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonDetailView(
            person: p,
            onNavigateToPerson: widget.onOpenPersonDetail,
            onJumpToTree: widget.onJumpToTree,
            onOpenKinship: widget.onSelectPersonForKinship,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    final query = _search.text.trim().toLowerCase();
    final generations =
        tree.people.map((p) => p.generationTier).toSet().toList()..sort();
    final filtered = tree.people
        .where(
          (p) =>
              (_tier == null || p.generationTier == _tier) &&
              (_status == 'all' ||
                  (_status == 'living' ? p.isLiving : !p.isLiving)) &&
              (query.isEmpty ||
                  '${p.fullName} ${p.traditionalName ?? ''} ${p.clanTotem ?? ''} ${p.villageOfOrigin ?? ''}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => tree.loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppText(
                          'Meet your family',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        FilledButton.icon(
                          onPressed: tree.canEditSelectedTree
                              ? () => PersonEditorDialog.show(context)
                              : null,
                          icon: const Icon(Icons.person_add_outlined),
                          label: const AppText('Add a person'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      '${tree.people.length} people · ${tree.people.where((p) => p.isLiving).length} living · ${generations.length} recorded generations',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: context.tr(
                          'Search a name, title, village or totem',
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: context.tr('Clear search'),
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
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
                          'living': 'Living',
                          'deceased': 'Deceased',
                        }.entries)
                          ChoiceChip(
                            label: AppText(entry.value),
                            selected: _status == entry.key,
                            onSelected: (_) =>
                                setState(() => _status = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const AppText('All generations'),
                            selected: _tier == null,
                            onSelected: (_) => setState(() => _tier = null),
                          ),
                          for (final tier in generations)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: AppText('Gen. $tier'),
                                selected: _tier == tier,
                                onSelected: (_) => setState(() => _tier = tier),
                              ),
                            ),
                        ],
                      ),
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
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 48),
                      const SizedBox(height: 12),
                      AppText(
                        tree.people.isEmpty
                            ? 'No people in this tree yet.'
                            : 'No people match these filters.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (tree.people.isNotEmpty)
                        TextButton(
                          onPressed: _clearFilters,
                          child: const AppText('Clear filters'),
                        )
                      else if (tree.canEditSelectedTree)
                        FilledButton(
                          onPressed: () => PersonEditorDialog.show(context),
                          child: const AppText('Add the first person'),
                        )
                      else if (tree.selectedTree == null)
                        TextButton(
                          onPressed: () => TreeManagerSheet.show(context),
                          child: const AppText('Choose or create a family'),
                        ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final p = filtered[i];
                    final links = tree.relationships
                        .where(
                          (r) => r.person1Id == p.id || r.person2Id == p.id,
                        )
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: KkevoPanel(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: MonogramMedallion(person: p, size: 56),
                              title: Text(
                                p.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: p.traditionalName?.isNotEmpty == true
                                  ? Text(p.traditionalName!)
                                  : AppText(
                                      p.isLiving ? 'Living' : 'In memory',
                                    ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _open(p),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(
                                  avatar: const Icon(
                                    Icons.hub_outlined,
                                    size: 16,
                                  ),
                                  label: AppText(
                                    '$links connection${links == 1 ? '' : 's'}',
                                  ),
                                ),
                                if (p.lifespanText.isNotEmpty)
                                  Chip(label: AppText(p.lifespanText)),
                                if (p.biography?.trim().isNotEmpty == true)
                                  const Chip(
                                    avatar: Icon(
                                      Icons.auto_stories_outlined,
                                      size: 16,
                                      color: RoyalTheme.coral,
                                    ),
                                    label: AppText('Story preserved'),
                                  ),
                              ],
                            ),
                            if (p.villageOfOrigin?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(p.villageOfOrigin!),
                              ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                TextButton(
                                  onPressed: () => _open(p),
                                  child: const AppText('View profile'),
                                ),
                                if (widget.onJumpToTree != null)
                                  TextButton(
                                    onPressed: () => widget.onJumpToTree!(p),
                                    child: const AppText('In the tree'),
                                  ),
                                if (widget.onSelectPersonForKinship != null)
                                  TextButton(
                                    onPressed: () =>
                                        widget.onSelectPersonForKinship!(p),
                                    child: const AppText('Relationship'),
                                  ),
                              ],
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
      ),
    );
  }
}
