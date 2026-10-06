import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/mobile_person_sheet.dart';
import '../../widgets/node_action_sheet.dart';
import '../../widgets/person_editor_dialog.dart';
import '../../widgets/tree_canvas.dart';
import '../../widgets/tree_manager_sheet.dart';
import '../family_connections_view.dart';

class TreeView extends StatefulWidget {
  final Function(Person)? onOpenKinshipForPerson, onOpenPersonDetail;
  const TreeView({
    super.key,
    this.onOpenKinshipForPerson,
    this.onOpenPersonDetail,
  });
  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  final _search = TextEditingController();
  TreeLayoutMode _layout = TreeLayoutMode.pedigree;
  int _centerRequest = 0;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _controls(TreeProvider tree, {VoidCallback? refresh}) {
    final tiers = tree.people.map((p) => p.generationTier).toSet().toList()
      ..sort();
    void layout(TreeLayoutMode value) {
      setState(() => _layout = value);
      refresh?.call();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const AppText('Family connections'),
              selected: _layout == TreeLayoutMode.pedigree,
              onSelected: (_) => layout(TreeLayoutMode.pedigree),
            ),
            ChoiceChip(
              label: const AppText('By generation'),
              selected: _layout == TreeLayoutMode.tiered,
              onSelected: (_) => layout(TreeLayoutMode.tiered),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const AppText('Whole family'),
              selected: tree.treeScope == TreeScope.extendedDynasty,
              onSelected: (_) => tree.setTreeScope(TreeScope.extendedDynasty),
            ),
            ChoiceChip(
              label: const AppText('Close family'),
              selected: tree.treeScope == TreeScope.immediateFamily,
              onSelected: (_) => tree.setTreeScope(TreeScope.immediateFamily),
            ),
          ],
        ),
        if (tiers.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const AppText('All generations'),
                selected: tree.generationFilter == null,
                onSelected: (_) => tree.setGenerationFilter(null),
              ),
              for (final tier in tiers)
                ChoiceChip(
                  label: AppText('Gen. $tier'),
                  selected: tree.generationFilter == tier,
                  onSelected: (_) => tree.setGenerationFilter(tier),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _showOptions(TreeProvider tree) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => Consumer<TreeProvider>(
        builder: (ctx, value, _) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * .8,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.paddingOf(ctx).bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  'Tree display',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                _controls(value, refresh: () => update(() {})),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const AppText('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final compact =
            constraints.maxWidth < 900 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4;
        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!compact)
                      Text(
                        tree.selectedTree?.name ?? 'My family tree',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              labelText: context.tr('Search a person'),
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
                        ),
                        if (compact)
                          IconButton.filledTonal(
                            tooltip: context.tr('Tree display'),
                            onPressed: () => _showOptions(tree),
                            icon: Badge(
                              isLabelVisible: tree.generationFilter != null,
                              child: const Icon(Icons.tune_rounded),
                            ),
                          ),
                        IconButton(
                          tooltip: context.tr('Refresh tree'),
                          onPressed: tree.isLoading
                              ? null
                              : () => tree.loadData(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    if (!compact) _controls(tree),
                  ],
                ),
              ),
              Expanded(
                child: tree.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tree.activeTreePeople.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_tree_outlined, size: 48),
                              const SizedBox(height: 12),
                              AppText(
                                tree.people.isEmpty
                                    ? 'Your tree is waiting for its first person.'
                                    : 'No people in this generation.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              if (tree.canEditSelectedTree &&
                                  tree.people.isEmpty)
                                FilledButton(
                                  onPressed: () =>
                                      PersonEditorDialog.show(context),
                                  child: const AppText('Add the first person'),
                                )
                              else if (tree.people.isNotEmpty)
                                TextButton(
                                  onPressed: () =>
                                      tree.setGenerationFilter(null),
                                  child: const AppText('Show all generations'),
                                )
                              else if (tree.selectedTree == null)
                                FilledButton(
                                  onPressed: () =>
                                      TreeManagerSheet.show(context),
                                  child: const AppText(
                                    'Choose or create a family',
                                  ),
                                ),
                              if (tree.selectedTree == null &&
                                  !tree.isOfflineMode &&
                                  !context.read<ApiService>().isPreviewMode)
                                TextButton.icon(
                                  onPressed: () =>
                                      FamilyConnectionsView.show(context),
                                  icon: const Icon(Icons.group_add_outlined),
                                  label: const AppText('Join my family'),
                                ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          TreeCanvas(
                            people: tree.activeTreePeople,
                            relationships: tree.relationships,
                            selectedPerson: tree.selectedPerson,
                            layoutMode: _layout,
                            searchQuery: _search.text,
                            centerRequest: _centerRequest,
                            orientation: tree.orientation,
                            onSelectPerson: (person) {
                              tree.selectPerson(person);
                              if (compact) {
                                MobilePersonSheet.show(
                                  context,
                                  person: person,
                                  onInspectKinship: () {
                                    widget.onOpenKinshipForPerson?.call(person);
                                  },
                                  onCenterInTree: () {
                                    tree.selectPerson(person);
                                    setState(() => _centerRequest++);
                                  },
                                  onOpenFullProfile: () {
                                    widget.onOpenPersonDetail?.call(person);
                                  },
                                );
                              }
                            },
                          ),
                          if (!compact && tree.selectedPerson != null)
                            Positioned(
                              top: 12,
                              right: 12,
                              bottom: 12,
                              width: 360,
                              child: Material(
                                color: Colors.transparent,
                                child: NodeActionSheet(
                                  person: tree.selectedPerson!,
                                  onClose: () => tree.selectPerson(null),
                                  onNavigateToPerson: tree.selectPerson,
                                  onOpenPersonDetail: widget.onOpenPersonDetail,
                                  onOpenKinship: widget.onOpenKinshipForPerson,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
