import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import '../services/api_service.dart';
import '../widgets/kkevo_ui.dart';
import '../widgets/edit_recovery.dart';

class ReportIssueView extends StatefulWidget {
  final Person? person;
  const ReportIssueView({super.key, this.person});
  @override
  State<ReportIssueView> createState() => _ReportIssueViewState();
}

class _ReportIssueViewState extends State<ReportIssueView>
    with WidgetsBindingObserver {
  late final ApiService _api;
  late final String _identity, _contextKey;
  final _details = TextEditingController();
  final _scroll = ScrollController();
  final _form = GlobalKey<FormState>();
  String _reason = 'PRIVACY';
  String? _error, _attempted, _key;
  bool _loading = true, _busy = false, _submitted = false;
  List<dynamic> _reports = [];
  static const reasons = {
    'PRIVACY': 'Privacy concern',
    'INCORRECT': 'Incorrect information',
    'INAPPROPRIATE': 'Inappropriate content',
    'OTHER': 'Other concern',
  };
  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _identity = _api.identity;
    _contextKey = context.read<TreeProvider>().contextKey;
    _details.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _details.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    final reports = await _api.getContentReports();
    if (!mounted || _api.identity != _identity) return;
    setState(() {
      _loading = false;
      if (reports == null) {
        _error = _api.lastError ?? 'Unable to load reports. Try again.';
      } else {
        _reports = reports;
        _error = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_api.identity != _identity ||
        context.read<TreeProvider>().contextKey != _contextKey) {
      setState(
        () => _error = 'The family or account has changed. Close this screen.',
      );
      return;
    }
    final fingerprint = '$_reason:${_details.text.trim()}';
    if (_attempted != fingerprint) {
      _key = 'report:${DateTime.now().microsecondsSinceEpoch}';
      _attempted = fingerprint;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final report = await _api.reportContent({
      'person_id': widget.person!.id,
      'reason': _reason,
      'details': _details.text.trim(),
      'request_key': _key,
    });
    if (!mounted || _api.identity != _identity) return;
    setState(() {
      _busy = false;
      if (report == null) {
        _error =
            _api.lastError ??
            'Unable to send the report. Your information is kept.';
      } else {
        _submitted = true;
        _reports.insert(0, report);
      }
    });
    if (report == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final changed = context.watch<ApiService>().identity != _identity;
    return EditRecoveryGuard(
      busy: _busy && !changed,
      dirty: !changed && !_submitted && _details.text.isNotEmpty,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('Report a concern'),
          actions: [
            IconButton(
              tooltip: context.tr('Refresh reports'),
              onPressed: _busy || changed ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: changed
            ? const Center(
                child: AppText('The account has changed. Close this screen.'),
              )
            : _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
            child: ListView(
              controller: _scroll,
                  padding: const EdgeInsets.all(24),
                  children: [
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
                    if (widget.person != null && !_submitted)
                      Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.person!.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            const AppText(
                              'Tell us about a problem with this profile, portrait or story. Include only the information needed to review it.',
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              initialValue: _reason,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: context.tr('Concern'),
                              ),
                              items: [
                                for (final entry in reasons.entries)
                                  DropdownMenuItem(
                                    value: entry.key,
                                    child: AppText(entry.value),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) => setState(() => _reason = value!),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _details,
                              enabled: !_busy,
                              maxLength: 2000,
                              minLines: 4,
                              maxLines: 8,
                              decoration: InputDecoration(
                                labelText: context.tr('What needs reviewing?'),
                              ),
                              validator: localizeValidator(
                                context,
                                (value) => value?.trim().isEmpty != false
                                    ? 'This field is required.'
                                    : null,
                              ),
                            ),
                            KkevoButton(
                              label: 'Send report',
                              icon: Icons.flag_outlined,
                              busy: _busy,
                              onPressed: _busy ? null : _submit,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    if (_submitted)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: AppText(
                          'Report received. You can follow its review here.',
                        ),
                      ),
                    AppText(
                      'My reports',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_reports.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: AppText(
                          'Your submitted reports and responses will appear here.',
                        ),
                      ),
                    for (final report in _reports)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                reasons[report['reason']] ?? 'Other concern',
                              ),
                              AppText(
                                switch (report['status']) {
                                  'IN_REVIEW' => 'Under review',
                                  'RESOLVED' => 'Resolved',
                                  _ => 'Received',
                                },
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(report['details'] as String),
                              if ((report['response'] as String? ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const AppText('Response'),
                                Text(report['response'] as String),
                              ],
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
}
