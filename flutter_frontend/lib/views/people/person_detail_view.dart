import '../../l10n/app_strings.dart';
import '../../widgets/relative_editor_dialog.dart';
import '../../widgets/person_editor_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../report_issue_view.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/person.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/monogram_medallion.dart';
import '../../widgets/kkevo_ui.dart';
import '../../widgets/story_editor.dart';
import '../../models/relationship.dart';

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
  late final String _openedContext;

  @override
  void initState() {
    super.initState();
    _openedContext = context.read<TreeProvider>().contextKey;
  }

  void _showEditPersonDialog(BuildContext context, Person person) =>
      PersonEditorDialog.show(context, person: person);

  void _showAddRelativeDialog(
    BuildContext context,
    Person person, {
    String defaultRole = 'child',
  }) {
    if (!context.read<TreeProvider>().canEditSelectedTree) return;
    RelativeEditorDialog.show(context, person, role: defaultRole);
  }

  void _showPhotoDialog(BuildContext context, Person person) {
    final tree = context.read<TreeProvider>();
    final openedContext = tree.contextKey;
    bool saving = false;
    String? error;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          bool canSavePortrait() {
            if (!ctx.mounted) return false;
            if (tree.contextKey == openedContext && tree.canEditSelectedTree) {
              return true;
            }
            update(
              () => error =
                  'The family or account has changed. Close this dialog and try again.',
            );
            return false;
          }

          Future<void> upload() async {
            if (!canSavePortrait()) return;
            update(() => saving = true);
            try {
              final photo = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                maxWidth: 1600,
                maxHeight: 1600,
                imageQuality: 85,
              );
              if (photo == null) return;
              if (!canSavePortrait()) return;
              final bytes = await photo.readAsBytes();
              if (bytes.length > 10 * 1024 * 1024) {
                throw const FormatException('Image exceeds 10 MB.');
              }
              if (!canSavePortrait()) return;
              final ok = await tree.uploadPortrait(
                person.id,
                bytes,
                photo.name,
              );
              if (!ok) {
                throw FormatException(
                  tree.lastSaveError ?? 'Unable to save portrait.',
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                update(
                  () => error = e is FormatException
                      ? e.message
                      : 'Unable to open this photo. Try again.',
                );
              }
            } finally {
              if (ctx.mounted) update(() => saving = false);
            }
          }

          return PopScope(
            canPop: !saving,
            child: AlertDialog(
              title: const AppText('Portrait'),
              content: AppText(
                error ??
                    'Choose a portrait from your device (maximum 10 MB). Initials appear when there is no photo.',
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: const AppText('Cancel'),
                ),
                if (person.profilePicture != null)
                  TextButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!canSavePortrait()) return;
                            update(() => saving = true);
                            final ok = await tree.updatePerson(person.id, {
                              'profile_picture': null,
                              'revision': person.revision,
                            });
                            if (ctx.mounted) {
                              if (ok) {
                                Navigator.pop(ctx);
                              } else {
                                update(() {
                                  saving = false;
                                  error =
                                      tree.lastSaveError ??
                                      'Unable to remove the portrait. Try again.';
                                });
                              }
                            }
                          },
                    child: const AppText('Remove portrait'),
                  ),
                ElevatedButton(
                  onPressed: saving ? null : upload,
                  child: AppText(saving ? 'Saving…' : 'Choose a photo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeletePerson(BuildContext context, Person person) {
    final tree = context.read<TreeProvider>();
    final openedContext = tree.contextKey;
    bool saving = false;
    String? error;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: const AppText('Delete this person?'),
            scrollable: true,
            content: AppText(
              error ??
                  '${person.fullName}, their connections, events and associated references will be deleted. This is permanent.',
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const AppText('Cancel'),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (tree.contextKey != openedContext ||
                            !tree.canEditSelectedTree) {
                          update(
                            () => error =
                                'The family has changed or is view only. Close this window.',
                          );
                          return;
                        }
                        update(() => saving = true);
                        final ok = await tree.deletePerson(person.id);
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx);
                          if (context.mounted) Navigator.of(context).pop();
                        } else {
                          update(() {
                            saving = false;
                            error =
                                tree.lastSaveError ??
                                'Unable to delete. Try again.';
                          });
                        }
                      },
                child: AppText(saving ? 'Deleting…' : 'Delete permanently'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    final available =
        _openedContext == tree.contextKey &&
        tree.people.any((p) => p.id == widget.person.id);
    if (!available) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Profile unavailable')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: AppText(
              'This person is no longer in the selected family. Return to your tree.',
            ),
          ),
        ),
      );
    }
    final person = tree.people.firstWhere((p) => p.id == widget.person.id);
    final parents = tree.getParentsOf(person.id),
        children = tree.getChildrenOf(person.id),
        partners = tree.getSpousesOf(person.id),
        siblings = tree.getSiblingsOf(person.id);
    final oldPartners = tree.relationships
        .where(
          (r) =>
              r.isSpousalLink &&
              !r.isCurrent &&
              (r.person1Id == person.id || r.person2Id == person.id),
        )
        .map((r) => r.person1Id == person.id ? r.person2Id : r.person1Id)
        .toSet();
    final former = tree.people
        .where((p) => oldPartners.contains(p.id))
        .toList();
    void treeJump() {
      widget.onJumpToTree?.call(person);
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppText('Their place in the family'),
        actions: [
          if (tree.canReportSelectedTree)
            IconButton(
              tooltip: context.tr('Report a concern'),
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportIssueView(person: person),
                ),
              ),
            ),
          if (tree.canEditSelectedTree)
            PopupMenuButton<String>(
              tooltip: context.tr('Profile options'),
              onSelected: (value) {
                if (value == 'edit') _showEditPersonDialog(context, person);
                if (value == 'photo') _showPhotoDialog(context, person);
                if (value == 'delete') _confirmDeletePerson(context, person);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: AppText('Edit details')),
                PopupMenuItem(
                  value: 'photo',
                  child: AppText('Change portrait'),
                ),
                PopupMenuItem(value: 'delete', child: AppText('Delete person')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KkevoPanel(
                  tint: RoyalTheme.green,
                  child: Column(
                    children: [
                      MonogramMedallion(person: person, size: 104),
                      const SizedBox(height: 16),
                      Text(
                        person.fullName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (person.traditionalName?.isNotEmpty == true)
                        Text(
                          person.traditionalName!,
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(
                            avatar: Icon(
                              person.isLiving
                                  ? Icons.eco_outlined
                                  : Icons.auto_awesome_outlined,
                              size: 18,
                            ),
                            label: AppText(
                              person.isLiving ? 'Living' : 'In memory',
                            ),
                          ),
                          if (person.lifespanText.isNotEmpty)
                            Chip(label: AppText(person.lifespanText)),
                        ],
                      ),
                      if (tree.canEditSelectedTree) ...[
                        const SizedBox(height: 16),
                        KkevoButton(
                          label: 'Add a relative',
                          icon: Icons.person_add_alt_1_rounded,
                          onPressed: () =>
                              _showAddRelativeDialog(context, person),
                        ),
                      ],
                      if (widget.onJumpToTree != null)
                        TextButton.icon(
                          onPressed: treeJump,
                          icon: const Icon(Icons.account_tree_outlined),
                          label: const AppText('View in tree'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppText(
                  'The connections that bring us together',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (parents.isEmpty &&
                    children.isEmpty &&
                    partners.isEmpty &&
                    siblings.isEmpty &&
                    former.isEmpty)
                  KkevoPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const KkevoIcon(
                          Icons.hub_outlined,
                          color: RoyalTheme.blue,
                        ),
                        const SizedBox(height: 12),
                        const AppText(
                          'Their family story starts here. Add a parent, child or relative to connect this profile to your family.',
                        ),
                      ],
                    ),
                  ),
                _group(
                  'Parents',
                  parents,
                  person,
                  tree,
                  Icons.arrow_upward_rounded,
                  RoyalTheme.blue,
                ),
                _group(
                  'Children',
                  children,
                  person,
                  tree,
                  Icons.arrow_downward_rounded,
                  RoyalTheme.green,
                ),
                _group(
                  'Partners',
                  partners,
                  person,
                  tree,
                  Icons.favorite_outline_rounded,
                  RoyalTheme.coral,
                ),
                _group(
                  'Siblings',
                  siblings,
                  person,
                  tree,
                  Icons.people_alt_outlined,
                  RoyalTheme.violet,
                ),
                _group(
                  'Former partners',
                  former,
                  person,
                  tree,
                  Icons.history_rounded,
                  RoyalTheme.coral,
                ),
                if (widget.onOpenKinship != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: KkevoButton(
                      label: 'Explore a relationship',
                      secondary: true,
                      icon: Icons.route_rounded,
                      onPressed: () => widget.onOpenKinship!(person),
                    ),
                  ),
                AppText(
                  'Their story',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                KkevoPanel(
                  tint: RoyalTheme.coral,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KkevoIcon(
                        Icons.auto_stories_outlined,
                        color: RoyalTheme.coral,
                      ),
                      const SizedBox(height: 12),
                      if (person.biography?.trim().isNotEmpty == true)
                        Text(person.biography!)
                      else
                        const AppText(
                          'A memory, a tradition, a moment… Keep what makes this person special.',
                        ),
                      if (tree.canEditSelectedTree) ...[
                        const SizedBox(height: 14),
                        KkevoButton(
                          label: person.biography?.trim().isNotEmpty == true
                              ? 'Add to their story'
                              : 'Write a memory',
                          secondary: true,
                          icon: Icons.edit_note_rounded,
                          onPressed: () async {
                            final ok = await StoryEditor.show(context, person);
                            if (ok == true && context.mounted) {
                              await showFamilySuccess(
                                context,
                                title: 'A story preserved',
                                message:
                                    'This memory is now part of ${person.firstName}’s profile.',
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppText(
                  'Their details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                KkevoPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _fact('Birth', person.dateOfBirth),
                      _fact('Death', person.dateOfDeath),
                      _fact('Place of birth', person.birthPlace),
                      _fact('Place of residence', person.currentLocation),
                      _fact('Village of origin', person.villageOfOrigin),
                      _fact('Clan totem', person.clanTotem),
                      if ([
                        person.dateOfBirth,
                        person.dateOfDeath,
                        person.birthPlace,
                        person.currentLocation,
                        person.villageOfOrigin,
                        person.clanTotem,
                      ].every((v) => v == null || v.isEmpty))
                        const AppText('These details have not been added yet.'),
                      if (tree.canEditSelectedTree)
                        TextButton.icon(
                          onPressed: () =>
                              _showEditPersonDialog(context, person),
                          icon: const Icon(Icons.edit_outlined),
                          label: const AppText('Complete profile'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fact(String label, String? value) => value == null || value.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 3),
              Text(value),
            ],
          ),
        );

  Widget _group(
    String title,
    List<Person> people,
    Person current,
    TreeProvider tree,
    IconData icon,
    Color color,
  ) {
    if (people.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: KkevoPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                KkevoIcon(icon, color: color, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: AppText(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            for (final other in people) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MonogramMedallion(person: other, size: 44),
                title: Text(other.fullName),
                subtitle: _linkLabel(current, other, tree) == null
                    ? null
                    : AppText(_linkLabel(current, other, tree)!),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  if (widget.onNavigateToPerson != null) {
                    widget.onNavigateToPerson!(other);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailView(
                          person: other,
                          onJumpToTree: widget.onJumpToTree,
                          onOpenKinship: widget.onOpenKinship,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _linkLabel(Person current, Person other, TreeProvider tree) {
    final matches = tree.relationships.where(
      (r) =>
          (r.person1Id == current.id && r.person2Id == other.id) ||
          (r.person2Id == current.id && r.person1Id == other.id),
    );
    if (matches.isEmpty) return null;
    final Relationship link = matches.first;
    return link.label;
  }
}
