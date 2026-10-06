import '../l10n/app_strings.dart';
import '../services/android_handoff.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/family_tree.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';
import '../services/api_service.dart';
import '../views/family_connections_view.dart';

class TreeManagerSheet extends StatefulWidget {
  const TreeManagerSheet({super.key});
  static void show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const TreeManagerSheet(),
  );
  @override
  State<TreeManagerSheet> createState() => _TreeManagerSheetState();
}

class _TreeManagerSheetState extends State<TreeManagerSheet> {
  bool _exporting = false;
  String? _error;

  Future<void> _edit({FamilyTree? tree}) async {
    final name = TextEditingController(text: tree?.name ?? '');
    final description = TextEditingController(text: tree?.description ?? '');
    final form = GlobalKey<FormState>();
    final provider = context.read<TreeProvider>();
    final openedContext = provider.contextKey;
    bool saving = false;
    String? error;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: AppText(
              tree == null ? 'Start a family tree' : 'Edit family tree',
            ),
            scrollable: true,
            content: SizedBox(
              width: 440,
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Semantics(
                          liveRegion: true,
                          child: AppText(
                            error!,
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: name,
                      enabled: !saving,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr('Family name *'),
                      ),
                      validator: localizeValidator(
                        context,
                        (v) => v == null || v.trim().isEmpty
                            ? 'Enter a name.'
                            : v.trim().length > 200
                            ? 'Maximum 200 characters.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: description,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.tr('Description'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const AppText('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        if (provider.contextKey != openedContext) {
                          update(
                            () => error =
                                'The family or account has changed. Close this form.',
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        final ok = tree == null
                            ? await provider.createTree(
                                    name.text.trim(),
                                    description.text.trim(),
                                  ) !=
                                  null
                            : await provider.updateTree(tree.id, {
                                'name': name.text.trim(),
                                'description': description.text.trim(),
                              });
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx);
                        } else {
                          update(() {
                            saving = false;
                            error =
                                provider.lastSaveError ??
                                'Unable to save the family. Your information is kept.';
                          });
                        }
                      },
                child: AppText(saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
    // Route disposal happens after its closing animation.
    Future.delayed(const Duration(milliseconds: 400), () {
      name.dispose();
      description.dispose();
    });
  }

  Future<void> _delete(FamilyTree tree) async {
    final provider = context.read<TreeProvider>();
    final openedContext = provider.contextKey;
    final name = TextEditingController();
    bool deleting = false;
    String? error;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => PopScope(
          canPop: !deleting,
          child: AlertDialog(
            title: const AppText('Delete this family tree?'),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  'All people, connections and events in “${tree.name}” will be deleted. This is permanent. Export your records before continuing.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: name,
                  enabled: !deleting,
                  decoration: InputDecoration(
                    labelText: context.tr('Enter the exact family name'),
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AppText(
                      error!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(ctx),
                child: const AppText('Cancel'),
              ),
              TextButton(
                onPressed: deleting
                    ? null
                    : () async {
                        if (name.text != tree.name) {
                          update(() => error = 'The name must match exactly.');
                          return;
                        }
                        if (provider.contextKey != openedContext) {
                          update(
                            () => error =
                                'The family or account has changed. Close this form.',
                          );
                          return;
                        }
                        update(() {
                          deleting = true;
                          error = null;
                        });
                        final ok = await provider.deleteTree(tree.id);
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx);
                        } else {
                          update(() {
                            deleting = false;
                            error =
                                provider.lastSaveError ??
                                'Unable to delete. Try again.';
                          });
                        }
                      },
                child: AppText(deleting ? 'Deleting…' : 'Delete permanently'),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), name.dispose);
  }

  Future<void> _export(FamilyTree tree) async {
    final api = context.read<ApiService>();
    final identity = api.identity;
    setState(() {
      _exporting = true;
      _error = null;
    });
    final data = await api.exportTreeData(treeId: tree.id);
    if (!mounted || identity != api.identity) return;
    setState(() => _exporting = false);
    if (data == null) {
      setState(() => _error = api.lastError ?? 'Unable to export. Try again.');
      return;
    }
    final json = const JsonEncoder.withIndent('  ').convert(data);
    String? copyMessage;
    bool copying = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: AppText('Export “${tree.name}”'),
          scrollable: true,
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  '${(data['people'] as List?)?.length ?? 0} people · ${(data['relationships'] as List?)?.length ?? 0} connections',
                ),
                const SizedBox(height: 12),
                const AppText(
                  'This JSON export includes profiles and connections. It does not include portrait or memory files.',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                if (copyMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: AppText(copyMessage!),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const AppText('Close'),
            ),
            if (AndroidHandoff.available)
              TextButton.icon(
                icon: const Icon(Icons.save_alt_rounded),
                label: const AppText('Save JSON file'),
                onPressed: copying
                    ? null
                    : () async {
                        if (api.identity != identity) return;
                        update(() {
                          copying = true;
                          copyMessage = null;
                        });
                        try {
                          final saved = await AndroidHandoff.saveJson(json);
                          if (ctx.mounted && api.identity == identity) {
                            update(
                              () => copyMessage = saved
                                  ? 'JSON file saved.'
                                  : 'File saving cancelled.',
                            );
                          }
                        } catch (_) {
                          if (ctx.mounted) {
                            update(
                              () => copyMessage =
                                  'Unable to save this file. Try again.',
                            );
                          }
                        } finally {
                          if (ctx.mounted) update(() => copying = false);
                        }
                      },
              ),
            FilledButton.icon(
              onPressed: copying
                  ? null
                  : () async {
                      update(() {
                        copying = true;
                        copyMessage = null;
                      });
                      try {
                        await Clipboard.setData(ClipboardData(text: json));
                        if (ctx.mounted) {
                          update(() => copyMessage = 'JSON export copied.');
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          update(
                            () => copyMessage =
                                'Unable to copy. Select the JSON text to copy it manually.',
                          );
                        }
                      } finally {
                        if (ctx.mounted) update(() => copying = false);
                      }
                    },
              icon: const Icon(Icons.copy),
              label: const AppText('Copy JSON'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(FamilyTree destination) async {
    final text = TextEditingController();
    final tree = context.read<TreeProvider>();
    final api = context.read<ApiService>();
    final openedContext = tree.contextKey;
    bool importing = false;
    bool acknowledgedCopy = false;
    String? error;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => PopScope(
          canPop: !importing,
          child: AlertDialog(
            title: const AppText('Import people'),
            scrollable: true,
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    'Destination: ${destination.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const AppText(
                    'Paste a JSON export. Its people will be added to this tree. Importing it again creates duplicates. Photo files are not transferred.',
                  ),
                  const SizedBox(height: 14),
                  if (AndroidHandoff.available)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const AppText('Open JSON file'),
                      onPressed: importing
                          ? null
                          : () async {
                              if (tree.contextKey != openedContext ||
                                  !tree.canManageSelectedTree) {
                                return;
                              }
                              update(() {
                                importing = true;
                                error = null;
                              });
                              try {
                                final content = await AndroidHandoff.openJson();
                                if (ctx.mounted &&
                                    tree.contextKey == openedContext &&
                                    content != null) {
                                  text.text = content;
                                  update(() => acknowledgedCopy = false);
                                }
                              } catch (_) {
                                if (ctx.mounted) {
                                  update(
                                    () => error =
                                        'Unable to open this file. Use UTF-8 JSON under 10 MB.',
                                  );
                                }
                              } finally {
                                if (ctx.mounted) {
                                  update(() => importing = false);
                                }
                              }
                            },
                    ),
                  TextField(
                    controller: text,
                    enabled: !importing,
                    onChanged: (_) => update(() => acknowledgedCopy = false),
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: context.tr('JSON export'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: acknowledgedCopy,
                    title: const AppText(
                      'I understand this adds copies. Importing the same file again creates duplicates.',
                    ),
                    onChanged: importing
                        ? null
                        : (value) =>
                              update(() => acknowledgedCopy = value == true),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Semantics(
                        liveRegion: true,
                        child: AppText(
                          error!,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: importing ? null : () => Navigator.pop(ctx),
                child: const AppText('Cancel'),
              ),
              FilledButton(
                onPressed: importing
                    ? null
                    : () async {
                        Map<String, dynamic> data;
                        try {
                          final parsed = jsonDecode(text.text.trim());
                          if (parsed is! Map<String, dynamic>) {
                            throw const FormatException();
                          }
                          data = parsed;
                        } catch (_) {
                          update(() => error = 'Paste a valid JSON document.');
                          return;
                        }
                        if (data['people'] is! List ||
                            data['relationships'] is! List ||
                            (data.containsKey('events') &&
                                data['events'] is! List)) {
                          update(
                            () => error =
                                'Use a family export with people and connections.',
                          );
                          return;
                        }
                        if (!acknowledgedCopy) {
                          update(
                            () => error =
                                'Confirm that you want to add copies before importing.',
                          );
                          return;
                        }
                        if (tree.contextKey != openedContext ||
                            !tree.canManageSelectedTree) {
                          update(
                            () => error =
                                'The destination has changed or is view only. Close this form.',
                          );
                          return;
                        }
                        final confirmed = await showDialog<bool>(
                          context: ctx,
                          builder: (reviewContext) => AlertDialog(
                            title: const AppText('Review these copies'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  destination.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                for (final entry in {
                                  'People': (data['people'] as List).length,
                                  'Connections':
                                      (data['relationships'] as List).length,
                                  'Events':
                                      (data['events'] as List? ?? []).length,
                                }.entries)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AppText(entry.key),
                                      Text('${entry.value}'),
                                    ],
                                  ),
                                const SizedBox(height: 16),
                                const AppText(
                                  'New copies will be added. Photo files are not included. Invalid records will be rejected together.',
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(reviewContext, false),
                                child: const AppText('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(reviewContext, true),
                                child: const AppText('Add these copies'),
                              ),
                            ],
                          ),
                        );
                        if (!ctx.mounted || confirmed != true) return;
                        if (tree.contextKey != openedContext ||
                            !tree.canManageSelectedTree) {
                          update(
                            () => error =
                                'The destination has changed or is view only. Close this form.',
                          );
                          return;
                        }
                        update(() {
                          importing = true;
                          error = null;
                        });
                        final ok = await api.importTreeData(
                          data,
                          treeId: destination.id,
                        );
                        if (!ctx.mounted) return;
                        if (ok) {
                          await tree.loadData(targetTreeId: destination.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } else {
                          update(() {
                            importing = false;
                            error =
                                api.lastError ??
                                'Unable to import. Check the records and connection.';
                          });
                        }
                      },
                child: AppText(importing ? 'Importing…' : 'Add records'),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), text.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    final auth = context.watch<AuthProvider>();
    final selected = tree.selectedTree;
    final online =
        !auth.isPreviewMode && !tree.isOfflineMode && !tree.isLoading;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        children: [
          AppText(
            'Family trees',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const AppText('Join your family or start a tree.'),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AppText(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (tree.trees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: AppText('No family trees yet.'),
            ),
          for (final t in tree.trees)
            ListTile(
              selected: selected?.id == t.id,
              leading: Icon(
                selected?.id == t.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(t.name),
              subtitle: AppText(
                '${t.canEdit || t.owner == auth.currentUser?.username ? 'Can edit' : 'View only'} · ${t.peopleCount} people',
              ),
              onTap: tree.isLoading
                  ? null
                  : () {
                      tree.selectTree(t);
                      Navigator.pop(context);
                    },
              trailing:
                  online &&
                      (t.canManage || t.owner == auth.currentUser?.username)
                  ? PopupMenuButton<String>(
                      tooltip: context.tr('Manage this family'),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _edit(tree: t);
                        } else if (value == 'delete') {
                          await _delete(t);
                        } else {
                          await tree.loadData(targetTreeId: t.id);
                          if (context.mounted &&
                              tree.selectedTree?.id == t.id &&
                              tree.canManageSelectedTree) {
                            await FamilyConnectionsView.show(
                              context,
                              treeId: t.id,
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'access',
                          child: AppText('Invitations and access'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: AppText('Edit name and description'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: AppText('Delete family tree'),
                        ),
                      ],
                    )
                  : null,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: online
                ? () => FamilyConnectionsView.show(context)
                : null,
            icon: const Icon(Icons.group_add_outlined),
            label: const AppText('Join my family'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: online ? () => _edit() : null,
            icon: const Icon(Icons.add),
            label: const AppText('Create a family tree'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: selected == null || !online || _exporting
                    ? null
                    : () => _export(selected),
                icon: const Icon(Icons.copy),
                label: AppText(_exporting ? 'Exporting…' : 'Export JSON'),
              ),
              OutlinedButton.icon(
                onPressed: !tree.canManageSelectedTree
                    ? null
                    : () => _import(selected!),
                icon: const Icon(Icons.upload),
                label: const AppText('Import JSON'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
