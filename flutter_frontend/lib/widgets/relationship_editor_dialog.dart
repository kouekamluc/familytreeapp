import '../services/edit_drafts.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';
import 'adaptive_form_dialog.dart';
import 'edit_recovery.dart';
import '../services/api_service.dart';
import 'person_editor_dialog.dart';
import 'kkevo_ui.dart';

class RelationshipEditorDialog extends StatefulWidget {
  final Relationship? relationship;
  const RelationshipEditorDialog({super.key, this.relationship});
  static Future<bool?> show(
    BuildContext context, {
    Relationship? relationship,
  }) async {
    final tree = context.read<TreeProvider>();
    if (!tree.canEditSelectedTree || tree.people.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Choose an editable family with at least two people.',
          ),
        ),
      );
      return false;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => RelationshipEditorDialog(relationship: relationship),
    );
    if (result == true && context.mounted) {
      await showFamilySuccess(
        context,
        title: 'Your family is growing closer!',
        message: 'The connection has been saved. Find it in your tree.',
      );
    }
    return result;
  }

  @override
  State<RelationshipEditorDialog> createState() =>
      _RelationshipEditorDialogState();
}

class _RelationshipEditorDialogState extends State<RelationshipEditorDialog>
    with WidgetsBindingObserver {
  EditDraftSession? _draft;
  final _form = GlobalKey<FormState>();
  late final TextEditingController _notes, _start, _end;
  late String _type, _openedContext;
  late bool _current;
  late int _first, _second;
  int _step = 0;
  bool _saving = false;
  String? _error;
  bool _conflict = false;
  late int _revision;
  late Map<String, dynamic> _initial;
  Map<String, dynamic> _payload() => {
    'person1': _first,
    'person2': _second,
    'relationship_type': _type,
    'is_current': _current,
    'notes': _notes.text.trim(),
    'start_date': _start.text.trim().isEmpty ? null : _start.text.trim(),
    'end_date': _end.text.trim().isEmpty ? null : _end.text.trim(),
  };
  Map<String, dynamic> _changes() => Map.fromEntries(
    _payload().entries.where((e) => e.value != _initial[e.key]),
  );
  bool get _dirty => _changes().isNotEmpty;
  Future<void> _review() async {
    final tree = context.read<TreeProvider>();
    if (_saving || tree.contextKey != _openedContext) return;
    setState(() => _saving = true);
    final latest = await context.read<ApiService>().getRelationship(
      widget.relationship!.id,
    );
    if (!mounted) return;
    if (latest == null ||
        tree.contextKey != _openedContext ||
        !tree.canEditSelectedTree) {
      setState(() {
        _saving = false;
        _error =
            'This record is unavailable or your access has changed. Your draft is kept.';
      });
      return;
    }
    final saved = latest.toJson();
    final draft = _changes();
    // Use recorded names in the review rather than database identifiers.
    for (final key in ['person1', 'person2']) {
      String name(dynamic id) =>
          tree.people.where((p) => p.id == id).firstOrNull?.fullName ??
          'Deleted profile';
      saved[key] = name(saved[key]);
      if (draft.containsKey(key)) draft[key] = name(draft[key]);
    }
    setState(() => _saving = false);
    final accepted = await reviewLatest(context, saved, draft, {
      'person1': 'First person',
      'person2': 'Second person',
      'relationship_type': 'Connection type',
      'notes': 'Notes',
      'is_current': 'Current connection',
      'start_date': 'Start date',
      'end_date': 'End date',
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (accepted && tree.contextKey == _openedContext) {
        _revision = latest.revision;
        _conflict = false;
        _error = null;
      }
    });
  }

  static const types = {
    'PARENT': ('Parent → child', Icons.account_tree_rounded, RoyalTheme.green),
    'ADOPTED': (
      'Adoptive parent → child',
      Icons.favorite_rounded,
      RoyalTheme.coral,
    ),
    'STEP': (
      'Stepparent → child',
      Icons.diversity_1_rounded,
      RoyalTheme.violet,
    ),
    'SPOUSE': (
      'Spouses / partners',
      Icons.favorite_border_rounded,
      RoyalTheme.coral,
    ),
    'SIBLING': ('Sibling', Icons.people_alt_rounded, RoyalTheme.blue),
  };
  @override
  void initState() {
    super.initState();
    final tree = context.read<TreeProvider>();
    final r = widget.relationship;
    _openedContext = tree.contextKey;
    _first = r?.person1Id ?? tree.people.firstOrNull?.id ?? 0;
    _second = r?.person2Id ?? tree.people.lastOrNull?.id ?? 0;
    _type = r?.relationshipType ?? 'PARENT';
    _current = r?.isCurrent ?? true;
    _notes = TextEditingController(text: r?.notes ?? '');
    _start = TextEditingController(text: r?.startDate ?? '');
    _end = TextEditingController(text: r?.endDate ?? '');
    _revision = r?.revision ?? 1;
    _initial = _payload();
    WidgetsBinding.instance.addObserver(this);
    final api = context.read<ApiService>();
    if (api.isAuthenticated && !api.isPreviewMode) {
      final identity = api.identity;
      _draft = EditDraftSession(
        EditDrafts(
          identity,
          '$_openedContext:relationship:${widget.relationship?.id ?? "new"}',
        ),
        () =>
            mounted &&
            api.identity == identity &&
            context.read<TreeProvider>().contextKey == _openedContext,
        () => {
          'values': _payload(),
          'initial': _initial,
          'revision': _revision,
          'step': _step,
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    }
    for (final c in [_notes, _start, _end]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _restoreDraft() async {
    final data = await _draft?.storage.read();
    if (!mounted || data == null || _dirty || _draft?.active() != true) return;
    final restore = await confirmRestoreDraft(context);
    if (!mounted || _draft?.active() != true) return;
    if (!restore) {
      _draft?.reset();
      return;
    }
    try {
      final values = data['values'] as Map<String, dynamic>;
      _first = values['person1'] as int;
      _second = values['person2'] as int;
      _type = values['relationship_type'] as String;
      _current = values['is_current'] as bool;
      _notes.text = values['notes'] as String;
      _start.text = values['start_date'] as String? ?? '';
      _end.text = values['end_date'] as String? ?? '';
      _initial = Map<String, dynamic>.from(data['initial'] as Map);
      _revision = data['revision'] as int;
      _step = (data['step'] as int).clamp(0, 2);
      setState(() {});
    } catch (_) {
      _draft?.reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _dirty) _draft?.flush();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draft?.dispose();
    _notes.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < 2) {
      if (!_form.currentState!.validate()) return;
      setState(() => _step++);
      return;
    }
    if (_saving || _conflict || !_form.currentState!.validate()) return;
    final tree = context.read<TreeProvider>();
    if (!tree.canEditSelectedTree ||
        tree.contextKey != _openedContext ||
        !tree.people.any((p) => p.id == _first) ||
        !tree.people.any((p) => p.id == _second) ||
        _first == _second) {
      setState(
        () => _error =
            'The family has changed or is view only. Your choices are kept.',
      );
      return;
    }
    final dateError =
        DateFormField.validateDate(_start.text) ??
        DateFormField.validateDate(_end.text);
    if (dateError != null) {
      setState(() => _error = dateError);
      return;
    }
    if (_start.text.isNotEmpty &&
        _end.text.isNotEmpty &&
        DateTime.parse(_end.text).isBefore(DateTime.parse(_start.text))) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = widget.relationship == null ? _payload() : _changes();
    if (widget.relationship != null) data['revision'] = _revision;
    final ok = widget.relationship == null
        ? await tree.addRelationship(_first, _second, _type, details: data)
        : await tree.updateRelationship(widget.relationship!.id, data);
    if (!mounted) return;
    if (ok) {
      await _draft?.finish();
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _conflict = tree.lastRevisionConflict;
        _error = tree.lastSaveError ?? 'Unable to save. Your choices are kept.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _draft?.observe(_dirty);
    final people = context.watch<TreeProvider>().people;
    final one = people.where((p) => p.id == _first).firstOrNull;
    final two = people.where((p) => p.id == _second).firstOrNull;
    final parental = ['PARENT', 'ADOPTED', 'STEP'].contains(_type);
    Widget personField(bool first) => DropdownButtonFormField<int>(
      key: ValueKey('${first ? 'first' : 'second'}:$_first:$_second'),
      initialValue: first ? one?.id : (two?.id == _first ? null : two?.id),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.tr(
          parental
              ? first
                    ? 'The parent'
                    : 'The child'
              : first
              ? 'First person'
              : 'Second person',
        ),
      ),
      items: people
          .where((p) => first || p.id != _first)
          .map(
            (p) => DropdownMenuItem(
              value: p.id,
              child: Text(p.fullName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      validator: localizeValidator(
        context,
        (v) => v == null ? 'Choose a person.' : null,
      ),
      onChanged: _saving
          ? null
          : (v) => setState(() {
              if (first) {
                _first = v!;
                if (_second == v) {
                  _second = people.where((p) => p.id != v).firstOrNull?.id ?? 0;
                }
              } else {
                _second = v!;
              }
            }),
    );
    return EditRecoveryGuard(
      busy: _saving,
      dirty: _dirty && _step == 0,
      onDiscard: () => _draft?.finish() ?? Future.value(),
      child: PopScope(
        canPop: !_saving && _step == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_saving && _step > 0) setState(() => _step--);
        },
        child: AdaptiveFormDialog(
          title: AppText(
            widget.relationship == null
                ? 'Connect your family'
                : 'Edit this connection',
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_conflict)
                    TextButton(
                      onPressed: _saving ? null : _review,
                      child: const AppText('Review the latest version'),
                    ),
                  AppText(
                    'STEP ${_step + 1} OF 3',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / 3,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  if (_step == 0) ...[
                    AppText(
                      'How are they connected?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    for (final entry in types.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KkevoChoiceTile(
                          title: entry.value.$1,
                          icon: entry.value.$2,
                          color: entry.value.$3,
                          selected: _type == entry.key,
                          onTap: () => setState(() => _type = entry.key),
                        ),
                      ),
                  ] else if (_step == 1) ...[
                    AppText(
                      'Who would you like to connect?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    personField(true),
                    Center(
                      child: IconButton(
                        tooltip: context.tr('Swap people'),
                        onPressed: () => setState(() {
                          final before = _first;
                          _first = _second;
                          _second = before;
                        }),
                        icon: const Icon(Icons.swap_vert_rounded),
                      ),
                    ),
                    personField(false),
                    const SizedBox(height: 16),
                    AppText(
                      parental
                          ? 'The parent will connect to the child in this direction. Generations will not be reversed.'
                          : 'This connection goes both ways.',
                    ),
                  ] else ...[
                    AppText(
                      'The right connection, in the right direction.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    KkevoPanel(
                      child: Column(
                        children: [
                          KkevoConnectionPreview(
                            from:
                                one?.fullName ?? context.tr('Deleted profile'),
                            to: two?.fullName ?? context.tr('Deleted profile'),
                            directional: parental,
                          ),
                          const SizedBox(height: 14),
                          AppText(
                            types[_type]!.$1,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_type == 'SPOUSE')
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const AppText('Current partnership'),
                        subtitle: const AppText(
                          'Turn off to record a former partnership.',
                        ),
                        value: _current,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _current = v),
                      ),
                    ExpansionTile(
                      title: const AppText('Dates and details (optional)'),
                      initiallyExpanded: widget.relationship != null,
                      children: [
                        DateFormField(
                          controller: _start,
                          label: 'Start date',
                          enabled: !_saving,
                        ),
                        DateFormField(
                          controller: _end,
                          label: 'End date',
                          enabled: !_saving,
                          validator: localizeValidator(context, (v) {
                            final start = DateTime.tryParse(_start.text.trim());
                            final end = DateTime.tryParse(v?.trim() ?? '');
                            return start != null &&
                                    end != null &&
                                    end.isBefore(start)
                                ? 'End date cannot be before start date.'
                                : null;
                          }),
                        ),
                        TextFormField(
                          controller: _notes,
                          enabled: !_saving,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: context.tr('Notes'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_step > 0) {
                        setState(() => _step--);
                      } else if (!_dirty || await confirmDiscard(context)) {
                        await _draft?.finish();
                        if (context.mounted) Navigator.pop(context, false);
                      }
                    },
              child: AppText(_step == 0 ? 'Cancel' : 'Back'),
            ),
            KkevoButton(
              label: _step < 2 ? 'Continue' : 'Confirm connection',
              icon: _step < 2
                  ? Icons.arrow_forward_rounded
                  : Icons.check_rounded,
              busy: _saving,
              onPressed: _saving || _conflict ? null : _next,
            ),
          ],
        ),
      ),
    );
  }
}
