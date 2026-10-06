import '../services/api_service.dart';
import '../services/edit_drafts.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import 'adaptive_form_dialog.dart';
import 'person_editor_dialog.dart';
import 'edit_recovery.dart';
import 'kkevo_ui.dart';

class RelativeEditorDialog extends StatefulWidget {
  final Person source;
  final String role;
  const RelativeEditorDialog({
    super.key,
    required this.source,
    this.role = 'child',
  });
  static Future<bool?> show(
    BuildContext context,
    Person source, {
    String role = 'child',
  }) async {
    if (!context.read<TreeProvider>().canEditSelectedTree) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => RelativeEditorDialog(source: source, role: role),
    );
    if (result == true && context.mounted) {
      await showFamilySuccess(
        context,
        title: 'A new branch!',
        message: 'The person and their connection have been saved together.',
      );
    }
    return result;
  }

  @override
  State<RelativeEditorDialog> createState() => _RelativeEditorDialogState();
}

class _RelativeEditorDialogState extends State<RelativeEditorDialog>
    with WidgetsBindingObserver {
  EditDraftSession? _draft;
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController(),
      _notes = TextEditingController(),
      _birth = TextEditingController(),
      _death = TextEditingController(),
      _traditional = TextEditingController(),
      _village = TextEditingController(),
      _totem = TextEditingController();
  late final TextEditingController _last;
  late final String _openedContext;
  late String _role;
  String _gender = 'O', _nature = 'PARENT';
  int _step = 0;
  bool _new = true, _saving = false, _living = true;
  int? _existingId, _coParentId;
  String? _error;
  bool get _dirty =>
      _first.text.isNotEmpty ||
      _last.text != widget.source.lastName ||
      [
        _notes,
        _birth,
        _death,
        _traditional,
        _village,
        _totem,
      ].any((c) => c.text.isNotEmpty) ||
      !_new ||
      _existingId != null ||
      _coParentId != null ||
      _nature != 'PARENT' ||
      !_living ||
      _role !=
          (['parent', 'father', 'mother'].contains(widget.role)
              ? 'parent'
              : ['sibling', 'brother', 'sister'].contains(widget.role)
              ? 'sibling'
              : widget.role) ||
      _gender !=
          (widget.role == 'father'
              ? 'M'
              : widget.role == 'mother'
              ? 'F'
              : 'O');
  @override
  void initState() {
    super.initState();
    _role = ['parent', 'father', 'mother'].contains(widget.role)
        ? 'parent'
        : ['sibling', 'brother', 'sister'].contains(widget.role)
        ? 'sibling'
        : widget.role;
    _last = TextEditingController(text: widget.source.lastName);
    _openedContext = context.read<TreeProvider>().contextKey;
    for (final c in [
      _first,
      _last,
      _notes,
      _birth,
      _death,
      _traditional,
      _village,
      _totem,
    ]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
    if (widget.role == 'father') _gender = 'M';
    if (widget.role == 'mother') _gender = 'F';
    WidgetsBinding.instance.addObserver(this);
    final api = context.read<ApiService>();
    if (api.isAuthenticated && !api.isPreviewMode) {
      final identity = api.identity;
      _draft = EditDraftSession(
        EditDrafts(
          identity,
          '$_openedContext:relative:${widget.source.id}:${widget.role}',
        ),
        () =>
            mounted &&
            api.identity == identity &&
            context.read<TreeProvider>().contextKey == _openedContext,
        () => {
          'first': _first.text,
          'last': _last.text,
          'notes': _notes.text,
          'birth': _birth.text,
          'death': _death.text,
          'traditional': _traditional.text,
          'village': _village.text,
          'totem': _totem.text,
          'role': _role,
          'gender': _gender,
          'nature': _nature,
          'step': _step,
          'new': _new,
          'living': _living,
          'existing': _existingId,
          'coparent': _coParentId,
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
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
      _first.text = data['first'] as String;
      _last.text = data['last'] as String;
      _notes.text = data['notes'] as String;
      _birth.text = data['birth'] as String;
      _death.text = data['death'] as String;
      _traditional.text = data['traditional'] as String;
      _village.text = data['village'] as String;
      _totem.text = data['totem'] as String;
      _role = data['role'] as String;
      _gender = data['gender'] as String;
      _nature = data['nature'] as String;
      _step = (data['step'] as int).clamp(0, 2);
      _new = data['new'] as bool;
      _living = data['living'] as bool;
      _existingId = data['existing'] as int?;
      _coParentId = data['coparent'] as int?;
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
    for (final c in [
      _first,
      _last,
      _notes,
      _birth,
      _death,
      _traditional,
      _village,
      _totem,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_step >= 1 && _new && DateFormField.validateDate(_birth.text) != null) {
      setState(() => _error = 'Check the birth date under Dates and roots.');
      return;
    }
    if (_step >= 1 && _new && !_living) {
      final dateError = DateFormField.validateDate(_death.text);
      final birth = DateTime.tryParse(_birth.text.trim());
      final death = DateTime.tryParse(_death.text.trim());
      if (dateError != null ||
          (birth != null && death != null && death.isBefore(birth))) {
        setState(() => _error = dateError ?? 'Death cannot be before birth.');
        return;
      }
    }
    if (_step < 2) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _step++);
      return;
    }
    final tree = context.read<TreeProvider>();
    if (!tree.canEditSelectedTree ||
        tree.contextKey != _openedContext ||
        !tree.people.any((p) => p.id == widget.source.id) ||
        (!_new && !tree.people.any((p) => p.id == _existingId)) ||
        (_coParentId != null && !tree.people.any((p) => p.id == _coParentId))) {
      setState(
        () => _error =
            'The family has changed or is view only. Your information is kept.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final person = await tree.createRelative(
      sourcePersonId: widget.source.id,
      role: _role,
      existingPersonId: _new ? null : _existingId,
      coParentId: _role == 'child' ? _coParentId : null,
      relationshipNotes: _notes.text.trim(),
      relationshipType: ['parent', 'child'].contains(_role) ? _nature : null,
      personData: !_new
          ? {}
          : {
              'first_name': _first.text.trim(),
              'last_name': _last.text.trim(),
              'gender': _gender,
              'generation_tier':
                  widget.source.generationTier +
                  (_role == 'child'
                      ? 1
                      : _role == 'parent'
                      ? -1
                      : 0),
              'is_living': _living,
              if (!_living && _death.text.trim().isNotEmpty)
                'date_of_death': _death.text.trim(),
              if (_birth.text.trim().isNotEmpty)
                'date_of_birth': _birth.text.trim(),
              'traditional_name': _traditional.text.trim(),
              'village_of_origin': _village.text.trim(),
              'clan_totem': _totem.text.trim(),
            },
    );
    if (!mounted) return;
    if (person != null) {
      await _draft?.finish();
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error =
            tree.lastSaveError ?? 'Unable to save. Your information is kept.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _draft?.observe(_dirty);
    final tree = context.watch<TreeProvider>();
    final others = tree.people.where((p) => p.id != widget.source.id).toList();
    final selected = others.where((p) => p.id == _existingId).firstOrNull;
    final coParent = others.where((p) => p.id == _coParentId).firstOrNull;
    final name = _new
        ? '${_first.text.trim()} ${_last.text.trim()}'.trim()
        : selected?.fullName ?? 'Choose a member';
    final parentLabel = _nature == 'ADOPTED'
        ? 'adoptive parent'
        : _nature == 'STEP'
        ? 'stepparent'
        : 'parent';
    final preview = _role == 'parent'
        ? '$name will be the $parentLabel of ${widget.source.fullName}.'
        : _role == 'child'
        ? '${widget.source.fullName} will be the $parentLabel of $name.'
        : _role == 'spouse'
        ? '${widget.source.fullName} and $name will be connected as partners.'
        : '${widget.source.fullName} and $name will be connected as siblings.';
    Widget field(
      TextEditingController c,
      String label, {
      bool required = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        enabled: !_saving,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: context.tr(label)),
        validator: localizeValidator(
          context,
          required
              ? (v) => v?.trim().isEmpty != false
                    ? 'This field is required.'
                    : v!.trim().length > 100
                    ? 'Maximum 100 characters.'
                    : null
              : null,
        ),
      ),
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
          title: const AppText('Add a relative'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                      'Who is this person to ${widget.source.firstName}?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    for (final entry in {
                      'parent': ('Their parent', Icons.account_tree_rounded),
                      'child': ('Their child', Icons.child_care_rounded),
                      'spouse': (
                        'Their partner',
                        Icons.favorite_border_rounded,
                      ),
                      'sibling': ('Their sibling', Icons.people_alt_rounded),
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KkevoChoiceTile(
                          title: entry.value.$1,
                          icon: entry.value.$2,
                          selected: _role == entry.key,
                          onTap: () => setState(() => _role = entry.key),
                        ),
                      ),
                    if (['parent', 'child'].contains(_role)) ...[
                      const SizedBox(height: 8),
                      const AppText('Type of relationship'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in {
                            'PARENT': 'Parent / child',
                            'ADOPTED': 'Adoption',
                            'STEP': 'Blended family',
                          }.entries)
                            ChoiceChip(
                              label: AppText(entry.value),
                              selected: _nature == entry.key,
                              onSelected: (_) =>
                                  setState(() => _nature = entry.key),
                            ),
                        ],
                      ),
                    ],
                  ] else if (_step == 1) ...[
                    AppText(
                      'One person, one profile.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const AppText(
                      'Already in the tree? Choose their existing profile to keep their story together.',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const AppText('New person'),
                          selected: _new,
                          onSelected: (_) => setState(() => _new = true),
                        ),
                        ChoiceChip(
                          label: const AppText('Existing person'),
                          selected: !_new,
                          onSelected: others.isEmpty
                              ? null
                              : (_) => setState(() => _new = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_new) ...[
                      field(_first, 'First name *', required: true),
                      field(_last, 'Last name *', required: true),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('Gender (optional)'),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'O',
                            child: AppText('Not specified'),
                          ),
                          DropdownMenuItem(
                            value: 'F',
                            child: AppText('Female'),
                          ),
                          DropdownMenuItem(value: 'M', child: AppText('Male')),
                        ],
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        maintainState: true,
                        title: const AppText('Dates and roots (optional)'),
                        children: [
                          DateFormField(
                            controller: _birth,
                            label: 'Date of birth',
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const AppText('Living person'),
                            value: _living,
                            onChanged: (value) =>
                                setState(() => _living = value),
                          ),
                          if (!_living)
                            DateFormField(
                              controller: _death,
                              label: 'Date of death',
                            ),
                          field(_traditional, 'Traditional name / title'),
                          field(_village, 'Village of origin'),
                          field(_totem, 'Clan totem'),
                        ],
                      ),
                    ] else
                      DropdownButtonFormField<int>(
                        initialValue: selected?.id,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('Person *'),
                        ),
                        items: others
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.fullName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        validator: localizeValidator(
                          context,
                          (v) => v == null ? 'Choose a person.' : null,
                        ),
                        onChanged: (v) => setState(() {
                          _existingId = v;
                          if (_coParentId == v) _coParentId = null;
                        }),
                      ),
                    if (_role == 'child' &&
                        others.any((p) => p.id != _existingId)) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        key: ValueKey('co:$_existingId'),
                        initialValue: coParent?.id ?? 0,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr('Other parent (optional)'),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: AppText('Not specified'),
                          ),
                          ...others
                              .where((p) => p.id != _existingId)
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    p.fullName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                        onChanged: (v) =>
                            setState(() => _coParentId = v == 0 ? null : v),
                      ),
                    ],
                  ] else ...[
                    const Center(
                      child: KkevoIcon(
                        Icons.hub_rounded,
                        color: RoyalTheme.blue,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppText(
                      'A new branch, the right connection.',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    KkevoPanel(
                      tint: RoyalTheme.blue,
                      child: Column(
                        children: [
                          KkevoConnectionPreview(
                            from: _role == 'parent'
                                ? name
                                : widget.source.fullName,
                            to: _role == 'parent'
                                ? widget.source.fullName
                                : name,
                            directional: _role == 'parent' || _role == 'child',
                          ),
                          const SizedBox(height: 18),
                          AppText(
                            preview,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_role == 'child' && _coParentId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AppText(
                          '${coParent?.fullName ?? 'Deleted profile'} will also be connected as $parentLabel.',
                        ),
                      ),
                    AppText(
                      _new
                          ? 'A new profile and its connection will be saved together.'
                          : 'The existing profile and its information will be kept.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notes,
                      enabled: !_saving,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          'Relationship details (optional)',
                        ),
                      ),
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
              onPressed: _saving ? null : _next,
            ),
          ],
        ),
      ),
    );
  }
}
