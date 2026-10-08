import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/family_branch.dart';
import '../models/family_tree.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';
import '../services/api_service.dart';
import '../widgets/tree_canvas.dart';

class PrivateBranchesView extends StatefulWidget {
  final int treeId;
  const PrivateBranchesView({super.key, required this.treeId});
  static Future<void> show(BuildContext context, int treeId) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => PrivateBranchesView(treeId: treeId)),
      );
  @override
  State<PrivateBranchesView> createState() => _PrivateBranchesViewState();
}

class _PrivateBranchesViewState extends State<PrivateBranchesView>
    with WidgetsBindingObserver {
  late final ApiService _api;
  late final String _identity;
  bool _busy = false, _loading = true, _foreground = true;
  String? _error;
  Map<String, dynamic> _data = {};
  Timer? _timer;
  int _version = 0;
  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _identity = _api.identity;
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground && !_busy && !_loading) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && !_busy) _load();
  }

  @override
  void dispose() {
    _version++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || _api.identity != _identity) return;
    final version = ++_version;
    final result = await _api.familyBranches(widget.treeId);
    if (!mounted || version != _version || _api.identity != _identity) return;
    setState(() {
      _loading = false;
      _data = result ?? {};
      _error = result == null
          ? 'Unable to load branch sharing. Try again.'
          : null;
    });
  }

  Future<void> _command(
    FamilyBranch branch,
    String action, {
    String? decision,
  }) async {
    if (_busy || _api.identity != _identity) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText(
          action == 'withdraw'
              ? 'Stop sharing this branch?'
              : decision == 'APPROVED'
              ? 'Confirm this branch connection?'
              : 'Remove this branch connection?',
        ),
        content: AppText(
          action == 'withdraw'
              ? 'The extended family will no longer receive these shared profiles. Your private tree is kept.'
              : decision == 'APPROVED'
              ? 'Verify the branch’s identity and placement. Only the selected profiles will appear. This does not grant access to the private tree.'
              : 'This branch will no longer appear in your extended tree.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AppText('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _api.identity != _identity) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _api.familyBranches(
      widget.treeId,
      payload: {
        'action': action,
        'link_id': branch.id,
        'revision': branch.revision,
        if (decision != null) 'decision': decision,
      },
    );
    if (!mounted || _api.identity != _identity) return;
    setState(() => _busy = false);
    if (result == null) {
      setState(
        () => _error =
            _api.lastError ??
            'Unable to update branch sharing. Refresh and try again.',
      );
      return;
    }
    await _load();
  }

  Future<void> _edit([FamilyBranch? branch]) async {
    final provider = context.read<TreeProvider>();
    final source = provider.selectedTree;
    if (_busy ||
        source?.id != widget.treeId ||
        !provider.canManageSelectedTree) {
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PrivateBranchEditor(
          source: source!,
          people: provider.people
              .where((p) => p.familyTreeId == widget.treeId)
              .toList(),
          relationships: provider.relationships,
          existing: branch,
        ),
      ),
    );
    if (mounted) await _load();
  }

  List<FamilyBranch> items(String key) => (_data[key] as List? ?? [])
      .map(
        (item) => FamilyBranch.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
  Widget _card(
    FamilyBranch branch, {
    bool outgoing = false,
    bool incoming = false,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(branch.label, style: Theme.of(context).textTheme.titleMedium),
          AppText(switch (branch.status) {
            'APPROVED' => branch.active ? 'Shared' : 'Needs new confirmation',
            'PENDING' => 'Awaiting confirmation',
            'WITHDRAWN' => 'Private again',
            _ => 'Declined',
          }),
          if (outgoing) Text(branch.targetName),
          if (outgoing || incoming)
            Text(
              '${context.tr(branch.connectionLabel)} · ${branch.attachmentName}',
            ),
          AppText('${branch.people.length} selected profiles'),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => SharedBranchView.show(
                        context,
                        widget.treeId,
                        branch.id,
                      ),
                child: const AppText('Preview shared profiles'),
              ),
              if (outgoing)
                TextButton(
                  onPressed: _busy ? null : () => _edit(branch),
                  child: const AppText('Change sharing'),
                ),
              if (outgoing && branch.status != 'WITHDRAWN')
                TextButton(
                  onPressed: _busy ? null : () => _command(branch, 'withdraw'),
                  child: const AppText('Stop sharing'),
                ),
              if (incoming && branch.status == 'PENDING')
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _command(branch, 'review', decision: 'APPROVED'),
                  child: const AppText('Approve'),
                ),
              if (incoming)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _command(branch, 'review', decision: 'REJECTED'),
                  child: const AppText('Decline'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    context.watch<ApiService>();
    if (_api.identity != _identity) {
      return Scaffold(
        appBar: AppBar(title: const AppText('Private branches')),
        body: const Center(
          child: AppText('The account has changed. Close this screen.'),
        ),
      );
    }
    final incoming = items('incoming'),
        outgoing = items('outgoing'),
        visible = items('visible');
    return Scaffold(
      appBar: AppBar(
        title: const AppText('Private branches'),
        actions: [
          IconButton(
            tooltip: context.tr('Refresh'),
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppText(
                  'Your own tree stays private. Connect a branch to an extended family and choose exactly which profiles they can see.',
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: AppText(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (tree.selectedTree?.id == widget.treeId &&
                    tree.canManageSelectedTree)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _edit(),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const AppText('Connect selected profiles'),
                  ),
                const SizedBox(height: 16),
                const AppText('Branches I share'),
                for (final branch in outgoing) _card(branch, outgoing: true),
                if (outgoing.isEmpty)
                  const AppText('No profiles are shared from this tree.'),
                const SizedBox(height: 20),
                const AppText('Connections to this extended family'),
                for (final branch in incoming) _card(branch, incoming: true),
                if (incoming.isEmpty)
                  for (final branch in visible) _card(branch),
                if (incoming.isEmpty && visible.isEmpty)
                  const AppText('No shared branches yet.'),
              ],
            ),
    );
  }
}

class PrivateBranchEditor extends StatefulWidget {
  final FamilyTree source;
  final List<Person> people;
  final List<Relationship> relationships;
  final FamilyBranch? existing;
  const PrivateBranchEditor({
    super.key,
    required this.source,
    required this.people,
    required this.relationships,
    this.existing,
  });
  @override
  State<PrivateBranchEditor> createState() => _PrivateBranchEditorState();
}

class _PrivateBranchEditorState extends State<PrivateBranchEditor> {
  late final ApiService _api;
  late final String _identity;
  late final TextEditingController _label;
  List<FamilyTree> _trees = [];
  List<Person> _anchors = [];
  final Set<int> _selected = {};
  int? _target, _root, _anchor;
  String _connection = 'EXISTING';
  int _step = 0, _targetLoad = 0;
  bool _busy = false, _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _identity = _api.identity;
    final branch = widget.existing;
    _label = TextEditingController(text: branch?.label ?? widget.source.name);
    _target = branch?.targetTreeId;
    _root = branch?.rootId;
    _anchor = branch?.attachmentId;
    _connection = branch?.connection ?? 'EXISTING';
    _selected.addAll(branch?.people.map((p) => p.id) ?? []);
    _load();
  }

  @override
  void dispose() {
    _targetLoad++;
    _label.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trees = await _api.getTrees();
    if (!mounted || _api.identity != _identity) return;
    setState(() {
      _trees = trees.where((t) => t.id != widget.source.id).toList();
      _loading = false;
    });
    if (_target != null) await _loadTarget(_target!);
  }

  Future<void> _loadTarget(int id) async {
    final version = ++_targetLoad;
    setState(() => _busy = true);
    final people = await _api.getPeople(treeId: id);
    if (!mounted || version != _targetLoad || _api.identity != _identity) {
      return;
    }
    setState(() {
      _anchors = people;
      _busy = false;
      if (!people.any((p) => p.id == _anchor)) _anchor = null;
    });
  }

  Future<void> _save() async {
    if (_busy || _api.identity != _identity) return;
    if (_label.text.trim().isEmpty ||
        _label.text.trim().length > 100 ||
        _root == null ||
        _target == null ||
        _anchor == null ||
        !_selected.contains(_root) ||
        _selected.length > 200) {
      setState(
        () => _error =
            'Choose the tree, connection, branch root and up to 200 shared profiles.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _api.familyBranches(
      widget.source.id,
      payload: {
        'action': 'publish',
        'source_tree_id': widget.source.id,
        'target_tree_id': _target,
        'root_id': _root,
        'attachment_id': _anchor,
        'label': _label.text.trim(),
        'connection': _connection,
        'shared_ids': _selected.toList(),
        if (widget.existing != null) 'link_id': widget.existing!.id,
        if (widget.existing != null) 'revision': widget.existing!.revision,
      },
    );
    if (!mounted || _api.identity != _identity) return;
    setState(() => _busy = false);
    if (result == null) {
      setState(
        () => _error =
            _api.lastError ??
            'Unable to share this branch. Your selections are kept.',
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<int>> options(List<Person> list) => list
        .map(
          (p) => DropdownMenuItem(
            value: p.id,
            child: Text(p.fullName, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();
    context.watch<ApiService>();
    return PopScope(
      canPop: !_busy || _api.identity != _identity,
      child: Scaffold(
        appBar: AppBar(title: const AppText('Connect a private branch')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _api.identity != _identity
            ? const Center(
                child: AppText('The account has changed. Close this screen.'),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppText(
                    _step == 0
                        ? 'Choose where this branch belongs'
                        : 'Choose what your relatives can see',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: AppText(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_step == 0) ...[
                    if (_busy) const LinearProgressIndicator(),
                    const AppText(
                      'Join the extended family first. Its owner confirms your branch’s placement. Your private tree stays separate.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _label,
                      enabled: !_busy,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: context.tr('Shared branch name'),
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _trees.any((t) => t.id == _target)
                          ? _target
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Extended family tree'),
                      ),
                      items: _trees
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                t.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _busy || widget.existing != null
                          ? null
                          : (id) {
                              setState(() {
                                _target = id;
                                _anchor = null;
                              });
                              _loadTarget(id!);
                            },
                    ),
                    if (_trees.isEmpty)
                      const AppText(
                        'Join or create your extended family before connecting this private tree.',
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _root,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Root of my private branch'),
                      ),
                      items: options(widget.people),
                      onChanged: _busy
                          ? null
                          : (id) => setState(() {
                              _root = id;
                              _selected.add(id!);
                            }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _connection,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          'Their connection to the extended tree',
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'EXISTING',
                          child: AppText('Same person'),
                        ),
                        DropdownMenuItem(
                          value: 'CHILD',
                          child: AppText('Child'),
                        ),
                        DropdownMenuItem(
                          value: 'SIBLING',
                          child: AppText('Sibling'),
                        ),
                        DropdownMenuItem(
                          value: 'SPOUSE',
                          child: AppText('Partner'),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _connection = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey('$_target:$_anchor:${_anchors.length}'),
                      initialValue: _anchor,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Connect to this person'),
                      ),
                      items: options(_anchors),
                      onChanged: _busy
                          ? null
                          : (id) => setState(() => _anchor = id),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed:
                          _busy ||
                              _root == null ||
                              _target == null ||
                              _anchor == null
                          ? null
                          : () => setState(() {
                              _step = 1;
                              _error = null;
                            }),
                      child: const AppText('Choose shared profiles'),
                    ),
                  ] else ...[
                    const AppText(
                      'Only checked profiles share their names, gender, birth and death dates, birthplace and living status. Only links between checked profiles appear. Stories, photos, accounts and unchecked profiles stay private.',
                    ),
                    const SizedBox(height: 12),
                    for (final person in widget.people)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(person.fullName),
                        subtitle: person.id == _root
                            ? const AppText('This profile connects your branch')
                            : null,
                        value: _selected.contains(person.id),
                        onChanged: _busy || person.id == _root
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  _selected.add(person.id);
                                } else {
                                  _selected.remove(person.id);
                                }
                              }),
                      ),
                    const SizedBox(height: 16),
                    AppText('${_selected.length} selected profiles'),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => showSharedGraph(
                              context,
                              _label.text.trim(),
                              widget.people
                                  .where((p) => _selected.contains(p.id))
                                  .toList(),
                              widget.relationships
                                  .where(
                                    (r) =>
                                        _selected.contains(r.person1Id) &&
                                        _selected.contains(r.person2Id),
                                  )
                                  .toList(),
                            ),
                      child: const AppText('Preview shared profiles'),
                    ),
                    const AppText(
                      'Changing the selected profiles or placement requires a new branch review. You can stop sharing at any time.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: AppText(
                        _busy ? 'Saving…' : 'Send branch for confirmation',
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _step = 0),
                      child: const AppText('Back'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

Future<void> showSharedProfile(BuildContext context, Person person) {
  final identity = context.read<ApiService>().identity;
  return showDialog<void>(
    context: context,
    builder: (ctx) => Consumer<ApiService>(
      builder: (ctx, api, _) => AlertDialog(
        title: api.identity == identity
            ? Text(person.fullName)
            : const AppText('Shared profile · view only'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: api.identity != identity
              ? [const AppText('The account has changed. Close this screen.')]
              : [
                  const AppText('Shared profile · view only'),
                  if (person.dateOfBirth != null)
                    Text('${ctx.tr('Date of birth')}: ${person.dateOfBirth}'),
                  if (person.dateOfDeath != null)
                    Text('${ctx.tr('Date of death')}: ${person.dateOfDeath}'),
                  if ((person.birthPlace ?? '').isNotEmpty)
                    Text('${ctx.tr('Place of birth')}: ${person.birthPlace}'),
                ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const AppText('Done'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showSharedGraph(
  BuildContext context,
  String label,
  List<Person> people,
  List<Relationship> relationships,
) {
  final identity = context.read<ApiService>().identity;
  final projection = people
      .map(
        (p) => Person(
          id: p.id,
          firstName: p.firstName,
          lastName: p.lastName,
          gender: p.gender,
          dateOfBirth: p.dateOfBirth,
          dateOfDeath: p.dateOfDeath,
          birthPlace: p.birthPlace,
          isLiving: p.isLiving,
        ),
      )
      .toList();
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (ctx) => Consumer<ApiService>(
        builder: (ctx, api, _) => Scaffold(
          appBar: AppBar(
            title: api.identity == identity
                ? Text(label)
                : const AppText('Shared branch'),
          ),
          body: api.identity != identity
              ? const Center(
                  child: AppText('The account has changed. Close this screen.'),
                )
              : TreeCanvas(
                  people: projection,
                  fitInitially: true,
                  relationships: relationships,
                  onSelectPerson: (p) => showSharedProfile(ctx, p),
                ),
        ),
      ),
    ),
  );
}

class SharedBranchView extends StatefulWidget {
  final int treeId, branchId;
  const SharedBranchView({
    super.key,
    required this.treeId,
    required this.branchId,
  });
  static Future<void> show(BuildContext context, int treeId, int branchId) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SharedBranchView(treeId: treeId, branchId: branchId),
        ),
      );
  @override
  State<SharedBranchView> createState() => _SharedBranchViewState();
}

class _SharedBranchViewState extends State<SharedBranchView>
    with WidgetsBindingObserver {
  late final ApiService _api;
  late final String _identity;
  FamilyBranch? _branch;
  bool _loading = true, _foreground = true;
  Timer? _timer;
  int _version = 0;
  int? _openProfile;
  Future<void> _showProfile(Person person) async {
    _openProfile = person.id;
    await showSharedProfile(context, person);
    _openProfile = null;
  }

  void _closeProfile() {
    if (_openProfile != null && mounted) {
      _openProfile = null;
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _identity = _api.identity;
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground) _load();
    });
  }

  @override
  void dispose() {
    _version++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && mounted) {
      _closeProfile();
      _version++;
      setState(() {
        _branch = null;
        _loading = true;
      });
    } else if (_foreground) {
      _load();
    }
  }

  Future<void> _load() async {
    final version = ++_version;
    final data = await _api.familyBranches(widget.treeId);
    if (!mounted || version != _version || _api.identity != _identity) return;
    FamilyBranch? found;
    for (final key in ['visible', 'incoming', 'outgoing']) {
      for (final item in data?[key] as List? ?? []) {
        if ((item as Map)['id'] == widget.branchId) {
          found = FamilyBranch.fromJson(Map<String, dynamic>.from(item));
          break;
        }
      }
    }
    setState(() {
      _branch = found;
      _loading = false;
    });
    if (_openProfile != null &&
        !(found?.people.any((p) => p.id == _openProfile) ?? false)) {
      _closeProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ApiService>();
    final branch = _api.identity == _identity ? _branch : null;
    return Scaffold(
      appBar: AppBar(
        title: branch == null
            ? const AppText('Shared branch')
            : Text(branch.label),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : branch == null
          ? const Center(
              child: AppText(
                'This branch is no longer shared or is unavailable.',
              ),
            )
          : TreeCanvas(
              people: branch.people,
              fitInitially: true,
              relationships: branch.relationships,
              onSelectPerson: _showProfile,
            ),
    );
  }
}
