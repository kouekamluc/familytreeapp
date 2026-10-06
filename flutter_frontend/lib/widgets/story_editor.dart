import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import 'kkevo_ui.dart';
import 'edit_recovery.dart';
import '../services/edit_drafts.dart';
import '../services/api_service.dart';
import 'monogram_medallion.dart';

class StoryEditor extends StatefulWidget {
  final Person person;
  const StoryEditor({super.key, required this.person});
  static Future<bool?> show(BuildContext context, Person person) =>
      Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => StoryEditor(person: person)),
      );
  @override
  State<StoryEditor> createState() => _StoryEditorState();
}

class _StoryEditorState extends State<StoryEditor> with WidgetsBindingObserver {
  EditDraftSession? _draft;
  bool _restoring = false;
  late final TextEditingController _story;
  late final String _openedContext;
  bool _saving = false;
  String? _error;
  bool _conflict = false;
  late int _revision;
  Future<void> _review() async {
    final tree = context.read<TreeProvider>();
    if (_saving || tree.contextKey != _openedContext) return;
    setState(() => _saving = true);
    final latest = await context.read<ApiService>().getPerson(widget.person.id);
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
    setState(() => _saving = false);
    final accepted = await reviewLatest(
      context,
      latest.toJson(),
      {'biography': _story.text.trim()},
      {'biography': 'Biography'},
    );
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

  @override
  void initState() {
    super.initState();
    _story = TextEditingController(text: widget.person.biography ?? '');
    _openedContext = context.read<TreeProvider>().contextKey;
    _revision = widget.person.revision;
    _story.addListener(() {
      if (mounted) setState(() {});
      if (!_restoring) {
        if (_story.text != (widget.person.biography ?? '')) {
          _draft?.changed();
        } else {
          _draft?.reset();
        }
      }
    });
    WidgetsBinding.instance.addObserver(this);
    final api = context.read<ApiService>();
    if (api.isAuthenticated && !api.isPreviewMode) {
      final identity = api.identity;
      _draft = EditDraftSession(
        EditDrafts(identity, '$_openedContext:story:${widget.person.id}'),
        () =>
            mounted &&
            api.identity == identity &&
            context.read<TreeProvider>().contextKey == _openedContext,
        () => {'story': _story.text, 'revision': _revision},
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
    }
  }

  Future<void> _restore() async {
    final data = await _draft?.storage.read();
    if (!mounted ||
        data == null ||
        _story.text != (widget.person.biography ?? '') ||
        _draft?.active() != true) {
      return;
    }
    final restore = await confirmRestoreDraft(context);
    if (!mounted || _draft?.active() != true) return;
    if (!restore) {
      _draft?.reset();
      return;
    }
    if (data['story'] is! String || data['revision'] is! int) {
      _draft?.reset();
      return;
    }
    _restoring = true;
    _story.text = data['story'] as String;
    setState(() => _revision = data['revision'] as int);
    _restoring = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        _story.text != (widget.person.biography ?? '')) {
      _draft?.flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draft?.dispose();
    _story.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tree = context.read<TreeProvider>();
    if (_saving || _conflict) return;
    if (!tree.canEditSelectedTree || tree.contextKey != _openedContext) {
      setState(
        () => _error =
            'The family has changed or is view only. Your draft is kept here.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await tree.updatePerson(widget.person.id, {
      'biography': _story.text.trim(),
      'revision': _revision,
    });
    if (!mounted) return;
    if (ok) {
      await _draft?.finish();
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _conflict = tree.lastRevisionConflict;
        _error = tree.lastSaveError ?? 'Unable to save. Your draft is kept.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => EditRecoveryGuard(
    busy: _saving,
    dirty: _story.text != (widget.person.biography ?? ''),
    onDiscard: () async {
      await _draft?.finish();
    },
    child: Scaffold(
      appBar: AppBar(title: const AppText('A memory to share')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        MonogramMedallion(person: widget.person, size: 60),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.person.fullName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppText(
                      'What would you like to remember?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const AppText(
                      'A memory, a passion, a job, a favourite saying… A few lines are enough. This will become their biography.',
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
                    if (_conflict)
                      TextButton(
                        onPressed: _saving ? null : _review,
                        child: const AppText('Review the latest version'),
                      ),
                    TextField(
                      controller: _story,
                      enabled: !_saving,
                      minLines: 8,
                      maxLines: 16,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: context.tr('Their story'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    KkevoButton(
                      label: 'Save this memory',
                      icon: Icons.check_rounded,
                      busy: _saving,
                      onPressed: _conflict ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
