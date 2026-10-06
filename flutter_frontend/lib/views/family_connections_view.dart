import '../l10n/app_strings.dart';
import 'dart:async';
import '../services/android_handoff.dart';
import '../widgets/person_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../config/royal_theme.dart';
import '../providers/tree_provider.dart';
import '../services/api_service.dart';

class FamilyConnectionsView extends StatefulWidget {
  final int? treeId;
  final String initialPath;
  const FamilyConnectionsView({
    super.key,
    this.treeId,
    this.initialPath = 'code',
  });
  static Future<bool?> show(
    BuildContext context, {
    int? treeId,
    String initialPath = 'code',
  }) => Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) =>
          FamilyConnectionsView(treeId: treeId, initialPath: initialPath),
    ),
  );
  @override
  State<FamilyConnectionsView> createState() => _FamilyConnectionsViewState();
}

class _FamilyConnectionsViewState extends State<FamilyConnectionsView>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _foreground = true;
  final _scroll = ScrollController();
  late final ApiService _api;
  late final String _identity;
  final _code = TextEditingController(),
      _parent = TextEditingController(),
      _grandparent = TextEditingController(),
      _parentBirth = TextEditingController(),
      _parentPlace = TextEditingController();
  final _first = TextEditingController(), _last = TextEditingController();
  String _path = 'code', _mode = 'EXISTING';
  int? _anchor, _through;
  String? _birth, _error;
  bool _busy = false, _loading = true;
  int _loadVersion = 0;
  Map<String, dynamic> _data = {};
  List<dynamic> _matches = [];
  bool get _owner => widget.treeId != null;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
    _api = context.read<ApiService>();
    _identity = _api.identity;
    _first.text = _api.currentUser?.firstName ?? '';
    _last.text = _api.currentUser?.lastName ?? '';
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground &&
          mounted &&
          !_busy &&
          !_loading &&
          _api.identity == _identity) {
        _load();
      }
    });
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && !_busy && _api.identity == _identity) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _scroll.dispose();
    for (final c in [
      _code,
      _parent,
      _grandparent,
      _parentBirth,
      _parentPlace,
      _first,
      _last,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _revealError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    final data = await _api.getFamilyAccess(treeId: widget.treeId);
    if (!mounted || _api.identity != _identity || version != _loadVersion) {
      return;
    }
    setState(() {
      _loading = false;
      if (data != null) {
        _data = data;
        _error = null;
      } else {
        _error = _api.lastError ?? 'Unable to load. Try again.';
      }
    });
  }

  Future<Map<String, dynamic>?> _command(
    Map<String, dynamic> payload, {
    bool reload = true,
  }) async {
    if (_busy || _api.identity != _identity) return null;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _api.familyAccess({
      if (_owner) 'tree_id': widget.treeId,
      ...payload,
    });
    if (!mounted || _api.identity != _identity) return null;
    setState(() {
      _busy = false;
      if (result == null) {
        _error =
            _api.lastError ??
            'Unable to complete this action. Your information is kept.';
      }
    });
    if (result == null) _revealError();
    if (result != null && reload) await _load();
    return result;
  }

  Future<bool> _confirm(String title, String explanation) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: AppText(title),
          content: AppText(explanation),
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
      ) ??
      false;

  Map<String, dynamic>? _person() {
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
      setState(() => _error = 'Enter your first and last name.');
      _revealError();
      return null;
    }
    return {
      'first_name': _first.text.trim(),
      'last_name': _last.text.trim(),
      'gender': 'O',
      if (_birth != null) 'date_of_birth': _birth,
    };
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool code = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      enabled: !_busy,
      textInputAction: TextInputAction.next,
      textCapitalization: code
          ? TextCapitalization.characters
          : TextCapitalization.words,
      autocorrect: !code,
      enableSuggestions: !code,
      maxLength: code ? 40 : 100,
      decoration: InputDecoration(
        labelText: context.tr(label),
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _card(String title, List<Widget> children, {bool rawTitle = false}) =>
      Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rawTitle)
                Text(title, style: Theme.of(context).textTheme.titleMedium)
              else
                AppText(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Future<void> _join({String? candidate}) async {
    final person = _person();
    if (person == null) return;
    if (candidate == null && _code.text.trim().isEmpty) {
      setState(() => _error = 'Enter the invitation code from your family.');
      _revealError();
      return;
    }
    final result = await _command(
      candidate == null
          ? {'action': 'redeem', 'code': _code.text.trim(), 'person': person}
          : {
              'action': 'request_match',
              'candidate': candidate,
              'person': person,
            },
    );
    if (result != null && mounted) {
      if (candidate == null) _code.clear();
      setState(() => _matches = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Request sent. The family owner will confirm your profile and access.',
          ),
        ),
      );
    }
  }

  Future<void> _invite() async {
    final result = await _command({
      'action': 'invite',
      'anchor_id': _anchor,
      'mode': _mode,
      if (_mode == 'GRANDCHILD') 'through_parent_id': _through,
    });
    if (result == null || !mounted || _api.identity != _identity) return;
    final code = result['code'] as String;
    bool copied = false;
    String? copyError;
    await showDialog(
      context: context,
      builder: (ctx) => Consumer<ApiService>(
        builder: (ctx, api, _) {
          if (api.identity != _identity) {
            return AlertDialog(
              title: const AppText("Account changed"),
              content: const AppText("Sign in again to continue."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const AppText("Done"),
                ),
              ],
            );
          }
          return StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
              title: const AppText('Invitation created'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    code,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const AppText(
                    'Valid for 7 days and one request. Give this code to the intended person. It is shown only here. You will still need to approve their access.',
                  ),
                  if (copyError != null)
                    AppText(
                      copyError!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_api.identity != _identity) return;
                    try {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (ctx.mounted) update(() => copied = true);
                    } catch (_) {
                      if (ctx.mounted) {
                        update(
                          () => copyError =
                              'Unable to copy. Select the code to copy it.',
                        );
                      }
                    }
                  },
                  child: AppText(copied ? 'Copied' : 'Copy code'),
                ),
                if (AndroidHandoff.available)
                  TextButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const AppText('Share invitation'),
                    onPressed: () async {
                      if (_api.identity != _identity) return;
                      try {
                        await AndroidHandoff.shareInvitation(
                          '${ctx.tr('Join my family in Kkevo Family. Create your own account, open Join my family, and enter this invitation code:')}\n$code\n${ctx.tr('Valid for 7 days. Family approval is required.')}',
                          ctx.tr('Share invitation'),
                        );
                      } catch (_) {
                        if (ctx.mounted) {
                          update(
                            () => copyError =
                                'Unable to share. Copy the code instead.',
                          );
                        }
                      }
                    },
                  ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const AppText('Done'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _joining() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const AppText(
        'Use your own account. An invitation or suggestion does not reveal private family records until the family confirms your access.',
      ),
      const SizedBox(height: 20),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'code',
            label: AppText('Invitation'),
            icon: Icon(Icons.mail_outline),
          ),
          ButtonSegment(
            value: 'ancestry',
            label: AppText('My ancestors'),
            icon: Icon(Icons.account_tree_outlined),
          ),
        ],
        selected: {_path},
        onSelectionChanged: _busy
            ? null
            : (v) => setState(() {
                _path = v.first;
                _matches = [];
                _error = null;
              }),
      ),
      const SizedBox(height: 16),
      _card('My family profile', [
        _field(_first, 'First name'),
        _field(_last, 'Last name'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const AppText('Date of birth (optional)'),
          subtitle: AppText(_birth ?? 'Not provided'),
          trailing: _birth == null
              ? const Icon(Icons.calendar_today_outlined)
              : IconButton(
                  tooltip: context.tr('Clear date'),
                  icon: const Icon(Icons.clear),
                  onPressed: _busy ? null : () => setState(() => _birth = null),
                ),
          onTap: _busy
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _birth == null
                        ? DateTime(2000)
                        : DateTime.parse(_birth!),
                    firstDate: DateTime(1800),
                    lastDate: DateTime.now(),
                  );
                  if (mounted && date != null) {
                    setState(
                      () => _birth =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    );
                  }
                },
        ),
      ]),
      if (_path == 'code')
        _card('Family code', [
          _field(_code, 'Invitation code', code: true),
          FilledButton.icon(
            onPressed: _busy ? null : () => _join(),
            icon: const Icon(Icons.send_outlined),
            label: const AppText('Request to join'),
          ),
        ])
      else
        _card('Find your family through your roots', [
          const AppText(
            'Enter a parent and one of their parents. Only families that enable discovery can appear. Names alone do not prove your identity.',
          ),
          const SizedBox(height: 16),
          _field(_parent, 'Parent’s full name'),
          _field(_grandparent, 'Their parent’s full name (your grandparent)'),
          ExpansionTile(
            title: const AppText('Parent details (optional)'),
            children: [
              DateFormField(
                controller: _parentBirth,
                label: 'Parent’s date of birth',
                enabled: !_busy,
              ),
              _field(_parentPlace, 'Parent’s place of birth'),
            ],
          ),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    if (_parent.text.trim().isEmpty ||
                        _grandparent.text.trim().isEmpty) {
                      setState(() => _error = 'Enter both full names.');
                      _revealError();
                      return;
                    }
                    final dateError = DateFormField.validateDate(
                      _parentBirth.text,
                    );
                    if (dateError != null) {
                      setState(() => _error = dateError);
                      _revealError();
                      return;
                    }
                    final result = await _command({
                      'action': 'matches',
                      'parent_name': _parent.text.trim(),
                      'grandparent_name': _grandparent.text.trim(),
                      if (_parentBirth.text.trim().isNotEmpty)
                        'parent_birth_date': _parentBirth.text.trim(),
                      if (_parentPlace.text.trim().isNotEmpty)
                        'parent_birth_place': _parentPlace.text.trim(),
                    }, reload: false);
                    if (result != null && mounted) {
                      setState(() => _matches = result['matches'] as List);
                      if (_matches.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: AppText(
                              'No close enough match. Ask your family for an invitation.',
                            ),
                          ),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.search),
            label: const AppText('Find a family'),
          ),
          for (final match in _matches)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statusBadge('SUGGESTED'),
                  const SizedBox(height: 8),
                  Text(
                    match['family_name'] as String,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  AppText(match['reason'] as String),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _join(candidate: match['candidate'] as String),
                    child: const AppText('Request confirmation'),
                  ),
                ],
              ),
            ),
        ]),
      const SizedBox(height: 16),
      AppText('My requests', style: Theme.of(context).textTheme.titleMedium),
      if ((_data['requests'] as List? ?? []).isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: AppText('Your requests and their responses will appear here.'),
        ),
      for (final item in _data['requests'] as List? ?? []) _requestCard(item),
    ],
  );

  String _status(String value) => switch (value) {
    'SUGGESTED' => 'Suggested family',
    'PENDING' => 'Awaiting confirmation',
    'APPROVED' => 'Accepted',
    'REJECTED' => 'Declined',
    'CANCELLED' => 'Cancelled',
    'ACTIVE' => 'Available',
    'REDEEMED' => 'Used',
    'REVOKED' => 'Revoked',
    _ => 'Expired',
  };

  Widget _statusBadge(String status) {
    final (color, icon) = switch (status) {
      'SUGGESTED' => (RoyalTheme.blue, Icons.search_rounded),
      'PENDING' => (RoyalTheme.primaryGold, Icons.schedule_rounded),
      'APPROVED' => (RoyalTheme.green, Icons.check_circle_outline_rounded),
      _ => (
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.info_outline_rounded,
      ),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: RoyalTheme.accentText(context, color)),
            const SizedBox(width: 8),
            Flexible(
              child: AppText(
                _status(status),
                style: TextStyle(
                  color: RoyalTheme.accentText(context, color),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(dynamic item) => _card(
    _owner ? item['applicant'] as String : item['family_name'] as String,
    [
      _statusBadge(item['status'] as String),
      const SizedBox(height: 12),
      if (_owner) ...[
        Text('${item['person']['first_name']} ${item['person']['last_name']}'),
        AppText(
          '${item['mode'] == 'EXISTING' ? 'Profile to confirm' : 'Child to connect'} : ${item['anchor_name'] ?? 'Deleted profile'}',
        ),
        if (item['person']['date_of_birth'] != null)
          AppText('Birth: ${item['person']['date_of_birth']}'),
        if ((item['evidence'] as Map? ?? {}).isNotEmpty)
          AppText(
            'Reported parent: ${item['evidence']['parent_name']}\nReported grandparent: ${item['evidence']['grandparent_name']}',
          ),
      ],
      if (item['status'] == 'PENDING')
        Wrap(
          spacing: 8,
          children: _owner
              ? [
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await _confirm(
                              'Confirm this member?',
                              'Check their identity and family relationship. The account will be able to view the whole family tree, including its profiles, portraits and stories. It will not be able to edit. An existing profile will be kept.',
                            )) {
                              await _command({
                                'action': 'review',
                                'request_id': item['id'],
                                'decision': 'APPROVED',
                              });
                            }
                          },
                    child: const AppText('Approve'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await _confirm(
                              'Decline this request?',
                              'This request will not give access to your tree.',
                            )) {
                              await _command({
                                'action': 'review',
                                'request_id': item['id'],
                                'decision': 'REJECTED',
                              });
                            }
                          },
                    child: const AppText('Decline'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _command({
                            'action': 'cancel',
                            'request_id': item['id'],
                          }),
                    child: const AppText('Cancel request'),
                  ),
                ],
        ),
      if (!_owner && item['tree_id'] != null)
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  final tree = context.read<TreeProvider>();
                  setState(() => _busy = true);
                  await tree.loadData(
                    targetTreeId: item['tree_id'] as int,
                    targetPersonId: item['person_id'] as int?,
                  );
                  if (!mounted || _api.identity != _identity) return;
                  if (tree.selectedTree?.id == item['tree_id'] &&
                      !tree.isOfflineMode) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      _busy = false;
                      _error =
                          'This access is no longer available. Refresh your requests.';
                    });
                  }
                },
          child: const AppText('Open my family'),
        ),
    ],
    rawTitle: true,
  );

  Widget _management() {
    final tree = context.watch<TreeProvider>();
    final people = tree.people
        .where((p) => p.familyTreeId == widget.treeId)
        .toList();
    final children = tree.relationships
        .where((r) => r.isParent && r.person1Id == _anchor)
        .map((r) => r.person2Id)
        .toSet();
    List<DropdownMenuItem<int>> options(Iterable<Person> list) => list
        .map(
          (p) => DropdownMenuItem(
            value: p.id,
            child: AppText(
              '${p.fullName}${p.birthYear.isEmpty ? '' : ' · ${p.birthYear}'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card('Invite a relative', [
          const AppText(
            'Choose their place in the tree. They will use or create their own account, then you will confirm their identity.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _mode,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('Connection type'),
            ),
            items: const [
              DropdownMenuItem(
                value: 'EXISTING',
                child: AppText('Existing profile'),
              ),
              DropdownMenuItem(
                value: 'CHILD',
                child: AppText('Child of a member'),
              ),
              DropdownMenuItem(
                value: 'GRANDCHILD',
                child: AppText('Grandchild of a member'),
              ),
            ],
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _mode = v!;
                    _through = null;
                  }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: ValueKey('anchor:$_anchor'),
            initialValue: people.any((p) => p.id == _anchor) ? _anchor : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr(
                _mode == 'EXISTING'
                    ? 'Their profile'
                    : _mode == 'CHILD'
                    ? 'Their parent'
                    : 'Their grandparent',
              ),
            ),
            items: options(people),
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _anchor = v;
                    _through = null;
                  }),
          ),
          if (_mode == 'GRANDCHILD') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey('through:$_anchor:$_through'),
              initialValue: _through,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Connecting parent'),
              ),
              items: options(people.where((p) => children.contains(p.id))),
              onChanged: _busy ? null : (v) => setState(() => _through = v),
            ),
            const AppText(
              'If the parent is missing, add them to the tree first. The grandparent → parent → child path will be preserved.',
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _busy ||
                    _anchor == null ||
                    (_mode == 'GRANDCHILD' && _through == null)
                ? null
                : _invite,
            icon: const Icon(Icons.mail_outline),
            label: const AppText('Create invitation'),
          ),
          if (people.isEmpty) const AppText('Add a person to this tree first.'),
        ]),
        _card('Family discovery', [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const AppText('Allow family suggestions'),
            subtitle: const AppText(
              'This family’s name can be suggested when a parent / grandparent path matches. Profiles remain private and you approve each request.',
            ),
            value: _data['discovery_enabled'] == true,
            onChanged: _busy
                ? null
                : (v) async {
                    if (!v ||
                        await _confirm(
                          'Enable family suggestions?',
                          'Your family’s name will be visible to people with matching ancestors. Private details will not be shown.',
                        )) {
                      await _command({'action': 'discovery', 'enabled': v});
                    }
                  },
          ),
        ]),
        AppText(
          'Requests to review',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if ((_data['requests'] as List? ?? []).isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: AppText('No requests yet.'),
          ),
        for (final item in _data['requests'] as List? ?? []) _requestCard(item),
        _card('Members and access', [
          if ((_data['members'] as List? ?? []).isEmpty)
            const AppText(
              'The owner is currently the only person managing this family.',
            ),
          for (final member in _data['members'] as List? ?? [])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: AppText(member['name'] as String),
              subtitle: AppText(
                '${member['role'] == 'EDITOR' ? 'Can edit people and connections' : 'View only'}${member['person_name'] == null ? '' : '\n${member['person_name']}'}',
              ),
              trailing: PopupMenuButton<String>(
                enabled: !_busy,
                onSelected: (action) async {
                  if (action == 'VIEWER' || action == 'EDITOR') {
                    if (await _confirm(
                      'Change access?',
                      action == 'EDITOR'
                          ? 'This account will be able to add, edit and delete people and relationships.'
                          : 'This account will be able to view this tree without editing it.',
                    )) {
                      await _command({
                        'action': 'role',
                        'user_id': member['user_id'],
                        'role': action,
                      });
                      await tree.loadData();
                    }
                  } else if (await _confirm(
                    action == 'remove'
                        ? 'Remove this access?'
                        : 'Transfer ownership?',
                    action == 'remove'
                        ? 'The account will lose access. Previously downloaded data cannot be erased remotely.'
                        : 'This member will become the owner. You will keep editing access and lose control of permissions.',
                  )) {
                    final result = await _command({
                      'action': action,
                      'user_id': member['user_id'],
                    }, reload: action != 'transfer');
                    await tree.loadData();
                    if (action == 'transfer' && result != null && mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'VIEWER', child: AppText('View only')),
                  PopupMenuItem(
                    value: 'EDITOR',
                    child: AppText('Allow editing'),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: AppText('Remove access'),
                  ),
                  PopupMenuItem(
                    value: 'transfer',
                    child: AppText('Transfer ownership'),
                  ),
                ],
              ),
            ),
        ]),
        _card('Invitations', [
          for (final invite in _data['invitations'] as List? ?? [])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: AppText(invite['anchor_name'] as String),
              subtitle: AppText(_status(invite['status'] as String)),
              trailing: ['ACTIVE', 'REDEEMED'].contains(invite['status'])
                  ? IconButton(
                      tooltip: context.tr('Revoke this invitation'),
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: _busy
                          ? null
                          : () async {
                              if (await _confirm(
                                'Revoke this code?',
                                'This code and its pending request will no longer grant access. Remove already approved access from the members list separately.',
                              )) {
                                await _command({
                                  'action': 'revoke',
                                  'invitation_id': invite['id'],
                                });
                              }
                            },
                    )
                  : null,
            ),
        ]),
        if ((_data['changes'] as List? ?? []).isNotEmpty)
          _card('Recent changes', [
            for (final change in _data['changes'] as List)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: AppText(
                  change['kind'] == 'JOIN_APPROVED'
                      ? 'Family connection confirmed'
                      : 'Profile corrected',
                ),
                subtitle: AppText('By ${change['actor']}'),
              ),
          ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final changed = context.watch<ApiService>().identity != _identity;
    return PopScope(
      canPop: changed || !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: AppText(_owner ? 'My family’s access' : 'Join my family'),
          actions: [
            IconButton(
              tooltip: context.tr('Refresh requests'),
              onPressed: _busy || changed ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: changed
            ? const Center(
                child: AppText('The account has changed. Close this screen.'),
              )
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _busy ? () async {} : _load,
                child: ListView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: AppText(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    _owner ? _management() : _joining(),
                  ],
                ),
              ),
      ),
    );
  }
}
