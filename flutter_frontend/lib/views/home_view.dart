import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';
import '../widgets/kkevo_ui.dart';
import '../widgets/monogram_medallion.dart';
import '../widgets/person_editor_dialog.dart';
import '../widgets/relative_editor_dialog.dart';
import '../widgets/story_editor.dart';
import '../widgets/tree_manager_sheet.dart';
import 'family_connections_view.dart';

class HomeView extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final ValueChanged<Person> onOpenPerson;
  const HomeView({
    super.key,
    required this.onNavigate,
    required this.onOpenPerson,
  });
  Future<void> _person(BuildContext context, {Person? person}) async {
    final saved = await PersonEditorDialog.show(context, person: person);
    if (saved == true && context.mounted) {
      await showFamilySuccess(
        context,
        title: person == null
            ? 'A place in your story!'
            : 'A memory preserved!',
        message: 'The information has been saved to your family.',
      );
    }
  }

  Future<void> _story(BuildContext context, Person person) async {
    final saved = await StoryEditor.show(context, person);
    if (saved == true && context.mounted) {
      await showFamilySuccess(
        context,
        title: 'A memory preserved!',
        message: 'This story is now part of your family.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    final auth = context.watch<AuthProvider>();
    final family = tree.selectedTree;
    final people = tree.people;
    final parents = tree.relationships.where((r) => r.isParent).toList();
    final generations = parents.any(
      (r) => parents.any((next) => next.person1Id == r.person2Id),
    );
    final stories = people
        .where((p) => p.biography?.trim().isNotEmpty == true)
        .length;
    final facts = [
      people.isNotEmpty,
      tree.relationships.isNotEmpty,
      generations,
      stories > 0,
      (family?.membersCount ?? 0) > 0,
    ];
    final completed = facts.where((v) => v).length;
    final focus = tree.focusPerson;
    final firstName = auth.isPreviewMode
        ? ''
        : auth.currentUser?.firstName?.trim() ?? '';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () => tree.loadData(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    firstName.isEmpty
                        ? 'Welcome to your family story.'
                        : 'Hello, $firstName!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'Every connection brings your story to life.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (tree.isLoading) const LinearProgressIndicator(),
                  if (family == null && !tree.isLoading)
                    _start(context)
                  else if (family != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: dark ? RoyalTheme.cardDark : RoyalTheme.green,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: RoyalTheme.greenDepth,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: RoyalTheme.greenDepth,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  'Your family at a glance',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: dark
                                            ? Colors.white
                                            : RoyalTheme.greenInk,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  family.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: dark
                                            ? Colors.white
                                            : RoyalTheme.greenInk,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: context.tr('Explore my tree'),
                            onPressed: () => onNavigate(1),
                            icon: const Icon(Icons.account_tree_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _stat(
                          context,
                          people.length,
                          'People',
                          RoyalTheme.green,
                        ),
                        _stat(
                          context,
                          tree.relationships.length,
                          'Connections',
                          RoyalTheme.blue,
                        ),
                        _stat(context, stories, 'Stories', RoyalTheme.coral),
                      ],
                    ),
                    TextButton.icon(
                      label: const AppText('Explore my tree'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      onPressed: () => onNavigate(1),
                    ),
                    if (tree.canEditSelectedTree) ...[
                      const SizedBox(height: 16),
                      _nextStep(context, facts, focus),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            'Your family journey',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: dark ? RoyalTheme.cardDark : RoyalTheme.mint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppText(
                            '$completed / 5',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: completed / 5,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _step(
                      context,
                      index: 1,
                      title: 'Add your first person',
                      subtitle: 'Start with yourself or someone close to you.',
                      icon: Icons.person_add_alt_1_rounded,
                      done: facts[0],
                      active: !facts[0],
                      color: RoyalTheme.green,
                      onTap: tree.canEditSelectedTree
                          ? () => _person(context)
                          : () => onNavigate(2),
                    ),
                    _step(
                      context,
                      index: 2,
                      title: 'Connect your family',
                      subtitle: 'Add a parent, child, partner or sibling.',
                      icon: Icons.link_rounded,
                      done: facts[1],
                      active: facts[0] && !facts[1],
                      color: RoyalTheme.blue,
                      onTap: tree.canEditSelectedTree && focus != null
                          ? () => RelativeEditorDialog.show(context, focus)
                          : () => onNavigate(3),
                    ),
                    _step(
                      context,
                      index: 3,
                      title: 'Discover another generation',
                      subtitle: 'Connect parents to grandparents.',
                      icon: Icons.account_tree_rounded,
                      done: facts[2],
                      active: facts[0] && facts[1] && !facts[2],
                      color: RoyalTheme.violet,
                      onTap: tree.canEditSelectedTree && focus != null
                          ? () => RelativeEditorDialog.show(
                              context,
                              focus,
                              role: 'parent',
                            )
                          : () => onNavigate(1),
                    ),
                    _step(
                      context,
                      index: 4,
                      title: 'Preserve a memory',
                      subtitle: 'Write a story, even a few lines.',
                      icon: Icons.auto_stories_rounded,
                      done: facts[3],
                      active: facts.take(3).every((v) => v) && !facts[3],
                      color: RoyalTheme.coral,
                      onTap: focus == null
                          ? () => onNavigate(2)
                          : tree.canEditSelectedTree
                          ? () => _story(context, focus)
                          : () => onOpenPerson(focus),
                    ),
                    _step(
                      context,
                      index: 5,
                      title: 'Bring your family together',
                      subtitle: tree.canManageSelectedTree
                          ? 'Invite a relative to their place in the tree.'
                          : 'Explore the people who share your story.',
                      icon: Icons.diversity_1_rounded,
                      done: facts[4],
                      active: facts.take(4).every((v) => v) && !facts[4],
                      color: RoyalTheme.darkGold,
                      onTap: tree.canManageSelectedTree
                          ? () => FamilyConnectionsView.show(
                              context,
                              treeId: family.id,
                            )
                          : () => onNavigate(2),
                    ),
                    if (completed == 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: KkevoPanel(
                          child: Row(
                            children: [
                              const KkevoIcon(
                                Icons.celebration_rounded,
                                color: RoyalTheme.coral,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppText(
                                  'Strong roots! Keep adding your family’s stories.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            'Your people',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onNavigate(2),
                          child: const AppText('See all'),
                        ),
                      ],
                    ),
                    if (people.isEmpty)
                      const AppText('People you add will appear here.'),
                    for (final p in people.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KkevoPanel(
                          padding: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: MonogramMedallion(person: p, size: 48),
                            title: Text(p.fullName),
                            subtitle: AppText(
                              p.biography?.isNotEmpty == true
                                  ? 'A story to discover'
                                  : 'A story to tell',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => onOpenPerson(p),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _start(BuildContext context) => KkevoPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: FamilyGrove(size: 205)),
        AppText(
          'Where does your story begin?',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const AppText(
          'Join your family’s tree or start a new one. You can always add details later.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        KkevoButton(
          label: 'Join my family',
          icon: Icons.mail_outline_rounded,
          onPressed: () => FamilyConnectionsView.show(context),
        ),
        const SizedBox(height: 12),
        KkevoButton(
          label: 'Start my family tree',
          secondary: true,
          icon: Icons.add_rounded,
          onPressed: () => TreeManagerSheet.show(context),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () =>
              FamilyConnectionsView.show(context, initialPath: 'ancestry'),
          icon: const Icon(Icons.travel_explore_rounded),
          label: const AppText('Find my family through my ancestors'),
        ),
      ],
    ),
  );
  Widget _stat(BuildContext context, int value, String label, Color color) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: RoyalTheme.accentText(context, color),
            ),
          ),
          const SizedBox(width: 6),
          AppText(
            value == 1
                ? switch (label) {
                    'People' => 'Person',
                    'Connections' => 'Connection',
                    'Stories' => 'Story',
                    _ => label,
                  }
                : label,
          ),
        ],
      );

  Widget _nextStep(BuildContext context, List<bool> facts, Person? focus) {
    final tree = context.read<TreeProvider>();
    var index = facts.indexOf(false);
    if (index < 0) index = 3;
    // A viewer cannot invite people; story contributions remain available.
    if (index == 4 && !tree.canManageSelectedTree) index = 3;
    final titles = [
      'Add your first person',
      'Connect your family',
      'Discover another generation',
      'Preserve a memory',
      'Bring your family together',
    ];
    final actions = <VoidCallback>[
      () => _person(context),
      () => focus == null
          ? onNavigate(2)
          : RelativeEditorDialog.show(context, focus),
      () {
        if (focus == null) {
          onNavigate(1);
          return;
        }
        final parent = tree.getParentsOf(focus.id).firstOrNull ?? focus;
        RelativeEditorDialog.show(context, parent, role: 'parent');
      },
      () => focus == null ? onNavigate(2) : _story(context, focus),
      () => FamilyConnectionsView.show(context, treeId: tree.selectedTree!.id),
    ];
    return KkevoPanel(
      tint: RoyalTheme.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: RoyalTheme.accentText(context, RoyalTheme.green),
                size: 20,
              ),
              const SizedBox(width: 8),
              AppText(
                'Next step',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppText(titles[index], style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          KkevoButton(
            label: 'Continue your story',
            icon: Icons.arrow_forward_rounded,
            onPressed: actions[index],
          ),
        ],
      ),
    );
  }

  Widget _step(
    BuildContext context, {
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool done,
    bool active = false,
    required Color color,
    required VoidCallback onTap,
  }) => KkevoJourneyStep(
    index: index,
    title: title,
    subtitle: subtitle,
    icon: icon,
    done: done,
    active: active,
    color: color,
    onTap: onTap,
    last: index == 5,
  );
}
