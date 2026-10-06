import '../l10n/app_strings.dart';
import 'adaptive_form_dialog.dart';
import 'edit_recovery.dart';
import '../services/edit_drafts.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import 'kkevo_ui.dart';

/// One form for the existing create and edit entry points.
class PersonEditorDialog extends StatefulWidget {
  final Person? person;
  const PersonEditorDialog({super.key, this.person});

  static Future<bool?> show(BuildContext context, {Person? person}) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (_) => PersonEditorDialog(person: person),
      );

  @override
  State<PersonEditorDialog> createState() => _PersonEditorDialogState();
}

class _PersonEditorDialogState extends State<PersonEditorDialog>
    with WidgetsBindingObserver {
  EditDraftSession? _draft;
  bool _restoring = false;
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late String _gender;
  late bool _living;
  late String _contextKey;
  bool _saving = false;
  String? _error;
  bool _conflict = false;
  late int _revision;
  late Map<String, dynamic> _initial;
  static const _labels = {
    'first_name': 'First name',
    'last_name': 'Last name',
    'gender': 'Gender',
    'is_living': 'Living person',
    'date_of_birth': 'Date of birth',
    'date_of_death': 'Date of death',
    'birth_place': 'Place of birth',
    'current_location': 'Place of residence',
    'traditional_name': 'Traditional name / title',
    'village_of_origin': 'Village of origin',
    'clan_totem': 'Clan totem',
    'generation_tier': 'Generation',
    'biography': 'Biography',
  };
  Map<String, dynamic> _payload() => {
    for (final e in _fields.entries) e.key: e.value.text.trim(),
    'gender': _gender,
    'is_living': _living,
    'generation_tier': int.tryParse(_fields['generation_tier']!.text.trim()),
    'date_of_birth': _fields['date_of_birth']!.text.trim().isEmpty
        ? null
        : _fields['date_of_birth']!.text.trim(),
    'date_of_death': _living || _fields['date_of_death']!.text.trim().isEmpty
        ? null
        : _fields['date_of_death']!.text.trim(),
  };
  Map<String, dynamic> _changes() => Map.fromEntries(
    _payload().entries.where((e) => e.value != _initial[e.key]),
  );
  bool get _dirty => _changes().isNotEmpty;
  void _changed() {
    if (mounted) setState(() {});
    if (_restoring) return;
    if (_dirty) {
      _draft?.changed();
    } else {
      _draft?.reset();
    }
  }

  Future<void> _cancel() async {
    if (_saving) return;
    if ((!_dirty || await confirmDiscard(context)) && mounted) {
      await _draft?.finish();
      if (mounted) Navigator.pop(context, false);
    }
  }

  Future<void> _review() async {
    final tree = context.read<TreeProvider>();
    if (_saving || tree.contextKey != _contextKey) return;
    setState(() => _saving = true);
    final latest = await context.read<ApiService>().getPerson(
      widget.person!.id,
    );
    if (!mounted) return;
    if (latest == null ||
        tree.contextKey != _contextKey ||
        !tree.canEditSelectedTree) {
      setState(() {
        _saving = false;
        _error =
            'This record is unavailable or your access has changed. Your draft is kept.';
      });
      return;
    }
    setState(() => _saving = false);
    final accepted = await reviewLatest(
      context,
      latest.toJson(),
      _changes(),
      _labels,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (accepted && tree.contextKey == _contextKey) {
        _revision = latest.revision;
        _conflict = false;
        _error = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    final values = {
      'first_name': p?.firstName ?? '',
      'last_name': p?.lastName ?? '',
      'traditional_name': p?.traditionalName ?? '',
      'village_of_origin': p?.villageOfOrigin ?? '',
      'clan_totem': p?.clanTotem ?? '',
      'birth_place': p?.birthPlace ?? '',
      'current_location': p?.currentLocation ?? '',
      'biography': p?.biography ?? '',
      'generation_tier': '${p?.generationTier ?? 1}',
      'date_of_birth': p?.dateOfBirth ?? '',
      'date_of_death': p?.dateOfDeath ?? '',
    };
    values.forEach(
      (key, value) => _fields[key] = TextEditingController(text: value),
    );
    _gender = p == null
        ? 'O'
        : (p.isMale
              ? 'M'
              : p.isFemale
              ? 'F'
              : 'O');
    _living = p?.isLiving ?? true;
    _contextKey = context.read<TreeProvider>().contextKey;
    _revision = p?.revision ?? 1;
    _initial = _payload();
    for (final field in _fields.values) {
      field.addListener(_changed);
    }
    WidgetsBinding.instance.addObserver(this);
    final api = context.read<ApiService>();
    if (api.isAuthenticated && !api.isPreviewMode) {
      final identity = api.identity;
      _draft = EditDraftSession(
        EditDrafts(identity, '$_contextKey:person:${p?.id ?? "new"}'),
        () =>
            mounted &&
            context.read<TreeProvider>().contextKey == _contextKey &&
            api.identity == identity,
        () => {
          'values': _payload(),
          'initial': _initial,
          'revision': _revision,
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
    }
  }

  Future<void> _restore() async {
    final data = await _draft?.storage.read();
    if (!mounted || data == null || _dirty || _draft?.active() != true) return;
    final restore = await confirmRestoreDraft(context);
    if (!mounted || _draft?.active() != true) return;
    if (!restore) {
      _draft?.reset();
      return;
    }
    final stored = data['values'];
    if (stored is! Map<String, dynamic> ||
        !['M', 'F', 'O'].contains(stored['gender']) ||
        stored['is_living'] is! bool ||
        data['initial'] is! Map ||
        data['revision'] is! int) {
      _draft?.reset();
      return;
    }
    final values = stored;
    _restoring = true;
    for (final e in _fields.entries) {
      e.value.text = '${values[e.key] ?? ''}';
    }
    setState(() {
      _gender = values['gender'] as String;
      _living = values['is_living'] as bool;
      _initial = Map<String, dynamic>.from(data['initial'] as Map);
      _revision = data['revision'] as int;
    });
    _restoring = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _dirty) _draft?.flush();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draft?.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _conflict || !_form.currentState!.validate()) return;
    final provider = context.read<TreeProvider>();
    if (!provider.canEditSelectedTree || provider.contextKey != _contextKey) {
      setState(
        () => _error =
            'The family has changed or is view only. Close this form and try again.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = widget.person == null ? _payload() : _changes();
    if (widget.person != null) data['revision'] = _revision;
    final ok = widget.person == null
        ? await provider.addPerson(data)
        : await provider.updatePerson(widget.person!.id, data);
    if (!mounted) return;
    if (ok) {
      await _draft?.finish();
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _conflict = provider.lastRevisionConflict;
        _error =
            provider.lastSaveError ??
            'Unable to save. Your information is kept.';
      });
    }
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _fields[key],
      enabled: !_saving,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: lines == 1
          ? TextInputAction.next
          : TextInputAction.newline,
      maxLines: lines,
      decoration: InputDecoration(labelText: context.tr(label)),
      validator: localizeValidator(context, (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'This field is required.';
        if (key == 'generation_tier' && int.tryParse(text) == null) {
          return 'Enter a generation number.';
        }
        if (['first_name', 'last_name'].contains(key) && text.length > 100) {
          return 'Maximum 100 characters.';
        }
        if (lines == 1 &&
            !['first_name', 'last_name', 'generation_tier'].contains(key) &&
            text.length > 200) {
          return 'Maximum 200 characters.';
        }
        return null;
      }),
    ),
  );

  @override
  Widget build(BuildContext context) => EditRecoveryGuard(
    busy: _saving,
    dirty: _dirty,
    onDiscard: () async {
      await _draft?.finish();
    },
    child: AdaptiveFormDialog(
      title: AppText(widget.person == null ? 'Add a person' : 'Edit person'),
      scrollable: true,
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              if (_conflict)
                TextButton(
                  onPressed: _saving ? null : _review,
                  child: const AppText('Review the latest version'),
                ),
              const AppText(
                'Start with a name. You can add the rest of their story later.',
              ),
              const SizedBox(height: 20),
              _field('first_name', 'First name *', required: true),
              _field('last_name', 'Last name *', required: true),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.tr('Gender')),
                items: const [
                  DropdownMenuItem(
                    value: 'O',
                    child: AppText('Other / not specified'),
                  ),
                  DropdownMenuItem(value: 'M', child: AppText('Male')),
                  DropdownMenuItem(value: 'F', child: AppText('Female')),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        setState(() => _gender = v!);
                        _changed();
                      },
              ),
              const SizedBox(height: 14),
              DateFormField(
                controller: _fields['date_of_birth']!,
                label: 'Date of birth',
                enabled: !_saving,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const AppText('Living person'),
                value: _living,
                onChanged: _saving
                    ? null
                    : (v) {
                        setState(() => _living = v);
                        _changed();
                      },
              ),
              if (!_living)
                DateFormField(
                  controller: _fields['date_of_death']!,
                  label: 'Date of death',
                  enabled: !_saving,
                  validator: localizeValidator(context, (value) {
                    final birth = DateTime.tryParse(
                      _fields['date_of_birth']!.text,
                    );
                    final death = DateTime.tryParse(value ?? '');
                    return birth != null &&
                            death != null &&
                            death.isBefore(birth)
                        ? 'Death cannot be before birth.'
                        : null;
                  }),
                ),
              ExpansionTile(
                maintainState: true,
                title: const AppText('Roots and details'),
                subtitle: const AppText(
                  'Optional — add details at your own pace',
                ),
                children: [
                  _field('birth_place', 'Place of birth'),
                  _field('current_location', 'Place of residence'),
                  _field('traditional_name', 'Traditional name / title'),
                  _field('village_of_origin', 'Village of origin'),
                  _field('clan_totem', 'Clan totem'),
                  _field('generation_tier', 'Generation *', required: true),
                ],
              ),
              ExpansionTile(
                maintainState: true,
                title: const AppText('A memory to keep'),
                children: [_field('biography', 'Biography', lines: 5)],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _cancel,
          child: const AppText('Cancel'),
        ),
        KkevoButton(
          label: 'Save',
          icon: Icons.check_rounded,
          busy: _saving,
          onPressed: _saving || _conflict ? null : _save,
        ),
      ],
    ),
  );
}

class DateFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  const DateFormField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.validator,
  });

  static String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return 'Use YYYY-MM-DD.';
    }
    final date = DateTime.tryParse(text);
    if (date == null ||
        date.year < 1 ||
        date.toIso8601String().substring(0, 10) != text) {
      return 'This date does not exist.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: context.tr(label),
        hintText: context.tr('YYYY-MM-DD (optional)'),
        suffixIcon: IconButton(
          tooltip: context.tr('Choose a date'),
          onPressed: !enabled
              ? null
              : () async {
                  final text = controller.text.trim();
                  final current = validateDate(text) == null
                      ? DateTime.tryParse(text)
                      : null;
                  final date = await showDatePicker(
                    context: context,
                    initialDate: current ?? DateTime.now(),
                    firstDate: DateTime(1),
                    lastDate: DateTime(9999, 12, 31),
                  );
                  if (date != null && context.mounted) {
                    controller.text =
                        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
          icon: const Icon(Icons.calendar_today_outlined),
        ),
      ),
      validator: localizeValidator(
        context,
        (value) => validateDate(value) ?? validator?.call(value),
      ),
    ),
  );
}
