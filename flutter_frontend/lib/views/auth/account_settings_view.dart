import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../widgets/adaptive_form_dialog.dart';
import '../../widgets/kkevo_ui.dart';
import '../family_connections_view.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});
  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  Map<String, dynamic>? _details;
  String? _detailsIdentity;
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiService>(),
        identity = context.read<ApiService>().identity;
    final result = await api.accountDetails();
    if (!mounted) return;
    if (api.identity != identity) {
      setState(() {
        _loading = false;
        _details = null;
        _error = 'The account has changed. Close this form.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _details = result;
      _detailsIdentity = identity;
      _error = result == null ? api.lastError : null;
    });
  }

  Future<void> _action(
    String action,
    String title,
    List<(String, String)> fields,
  ) async {
    final api = context.read<ApiService>(),
        identity = context.read<ApiService>().identity;
    final form = GlobalKey<FormState>();
    final controllers = {
      for (final field in fields)
        field.$1: TextEditingController(
          text: field.$1 == 'first_name'
              ? api.currentUser?.firstName
              : field.$1 == 'last_name'
              ? api.currentUser?.lastName
              : '',
        ),
    };
    bool busy = false;
    String? error;
    var success = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => PopScope(
          canPop: !busy,
          child: AdaptiveFormDialog(
            title: AppText(title),
            content: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (action == 'request_deletion') ...[
                    const AppText(
                      'This submits a deletion request for review. No records are deleted immediately. Shared family history and ownership must be reviewed before completion.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (action == 'change_password') ...[
                    const AppText(
                      'Changing your password signs out your existing sessions. Personal login keys remain valid until revoked.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (final field in fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: controllers[field.$1],
                        enabled: !busy,
                        obscureText: field.$1.contains('password'),
                        autocorrect: false,
                        maxLength: field.$1.endsWith('_name') ? 30 : null,
                        decoration: InputDecoration(
                          labelText: context.tr(field.$2),
                        ),
                        validator: localizeValidator(context, (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Complete this field.';
                          }
                          if (field.$1 == 'confirmation' &&
                              v != controllers['new_password']?.text) {
                            return 'Passwords must match.';
                          }
                          return null;
                        }),
                      ),
                    ),
                  if (error != null)
                    Semantics(
                      liveRegion: true,
                      child: AppText(
                        error!,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const AppText('Cancel'),
              ),
              KkevoButton(
                label: title,
                busy: busy,
                onPressed: busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        if (api.identity != identity) {
                          update(
                            () => error =
                                'The account has changed. Close this form.',
                          );
                          return;
                        }
                        update(() {
                          busy = true;
                          error = null;
                        });
                        final result = await api.accountAction({
                          'action': action,
                          for (final field in fields)
                            if (field.$1 != 'confirmation')
                              field.$1: field.$1.contains('password')
                                  ? controllers[field.$1]!.text
                                  : controllers[field.$1]!.text.trim(),
                        });
                        if (!ctx.mounted) return;
                        if (api.identity != identity) {
                          update(() {
                            busy = false;
                            error = 'The account has changed. Close this form.';
                          });
                          return;
                        }
                        if (result == null) {
                          update(() {
                            busy = false;
                            error =
                                api.lastError ??
                                'Unable to complete this action.';
                          });
                          return;
                        }
                        success = true;
                        Navigator.pop(ctx);
                      },
              ),
            ],
          ),
        ),
      ),
    );
    // The closing dialog still paints its fields during the route transition.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (!mounted || api.identity != identity || !success) return;
    if (action == 'change_password') {
      await api.logout();
      if (mounted) Navigator.pop(context);
    } else {
      await _load();
    }
  }

  Future<void> _verify() async {
    final api = context.read<ApiService>(),
        identity = context.read<ApiService>().identity;
    setState(() => _loading = true);
    final result = await api.accountAction({'action': 'verify_email'});
    if (!mounted) return;
    if (api.identity != identity) {
      setState(() {
        _loading = false;
        _details = null;
        _error = 'The account has changed. Close this form.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _error = result == null ? api.lastError : null;
    });
    if (result != null) {
      await _action('confirm_email', 'Verify email', [('code', 'Email code')]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>(), user = api.currentUser;
    final changed = _details != null && _detailsIdentity != api.identity;
    return Scaffold(
      appBar: AppBar(title: const AppText('Account and security')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (changed) ...[
                  const AppText('The account has changed. Close this form.'),
                  TextButton(
                    onPressed: _load,
                    child: const AppText('Try again'),
                  ),
                ],
                if (_error != null) ...[
                  AppText(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: _load,
                    child: const AppText('Try again'),
                  ),
                ],
                if (_details != null && !changed) ...[
                  KkevoPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          user?.displayName ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(user?.email ?? ''),
                        const SizedBox(height: 12),
                        AppText(
                          user?.emailVerified == true
                              ? 'Email verified'
                              : 'Verify your email to enable password recovery.',
                        ),
                        if (user?.emailVerified != true)
                          TextButton.icon(
                            onPressed: _verify,
                            icon: const Icon(Icons.mark_email_read_outlined),
                            label: const AppText('Verify email'),
                          ),
                        TextButton(
                          onPressed: () =>
                              _action('edit_account', 'Save account details', [
                                ('first_name', 'First name'),
                                ('last_name', 'Last name'),
                                ('current_password', 'Current password'),
                              ]),
                          child: const AppText('Edit account details'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded),
                    title: const AppText('Change password'),
                    onTap: () => _action('change_password', 'Change password', [
                      ('current_password', 'Current password'),
                      ('new_password', 'New password'),
                      ('confirmation', 'Confirm new password'),
                    ]),
                  ),
                  const Divider(),
                  AppText(
                    'Account deletion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const AppText(
                    'Shared family history is not automatically erased when you request account deletion.',
                  ),
                  if ((_details!['owned_families'] as List? ?? [])
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const AppText(
                      'You own these families. Review ownership before deletion:',
                    ),
                    for (final tree in _details!['owned_families'] as List)
                      ListTile(
                        title: Text(tree['name'] as String),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => FamilyConnectionsView.show(
                          context,
                          treeId: tree['id'] as int,
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  if (_details!['deletion_status'] == 'PENDING') ...[
                    const AppText(
                      'Deletion requested. Pending review; no records have been deleted.',
                    ),
                    TextButton(
                      onPressed: () => _action(
                        'cancel_deletion',
                        'Cancel deletion request',
                        [('current_password', 'Current password')],
                      ),
                      child: const AppText('Cancel deletion request'),
                    ),
                  ] else
                    KkevoButton(
                      label: 'Request account deletion',
                      secondary: true,
                      onPressed: () => _action(
                        'request_deletion',
                        'Request account deletion',
                        [('current_password', 'Current password')],
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
