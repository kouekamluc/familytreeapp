import '../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/heritage_key.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class HeritageVaultView extends StatefulWidget {
  const HeritageVaultView({super.key});
  @override
  State<HeritageVaultView> createState() => _HeritageVaultViewState();
}

class _HeritageVaultViewState extends State<HeritageVaultView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().fetchHeritageKeys();
    });
  }

  Future<void> _copy(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Personal key copied. Keep it private.'),
        ),
      );
    }
  }

  Future<void> _generate() async {
    final name = TextEditingController();
    final form = GlobalKey<FormState>();
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();
    final identity = api.identity;
    String role = 'FAMILY_MEMBER';
    String? error;
    bool saving = false;
    String? issued;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: const AppText('Create a personal key'),
            scrollable: true,
            content: SizedBox(
              width: 440,
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppText(
                      'This key signs in to your account with all your current permissions. It does not create limited access for another person.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: context.tr('Key name *'),
                        hintText: context.tr('e.g. My phone'),
                      ),
                      validator: localizeValidator(
                        context,
                        (v) => v == null || v.trim().isEmpty
                            ? 'Give this key a name.'
                            : v.trim().length > 100
                            ? 'Maximum 100 characters.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Descriptive category'),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'FAMILY_MEMBER',
                          child: AppText('Family member'),
                        ),
                        DropdownMenuItem(
                          value: 'ROYAL_PATRIARCH',
                          child: AppText('Family elder'),
                        ),
                        DropdownMenuItem(
                          value: 'CURATOR',
                          child: AppText('Editor'),
                        ),
                        DropdownMenuItem(
                          value: 'GUEST_VIEWER',
                          child: AppText('Viewer'),
                        ),
                      ],
                      onChanged: saving ? null : (v) => update(() => role = v!),
                    ),
                    const SizedBox(height: 8),
                    const AppText(
                      'The category does not change sign-in permissions.',
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
                        if (api.identity != identity) {
                          update(
                            () => error =
                                'The account has changed. Close this form.',
                          );
                          return;
                        }
                        update(() {
                          saving = true;
                          error = null;
                        });
                        final created = await auth.generateHeritageKey(
                          name: name.text.trim(),
                          role: role,
                        );
                        if (!ctx.mounted) return;
                        if (created != null) {
                          issued = created.key;
                          Navigator.pop(ctx);
                        } else {
                          update(() {
                            saving = false;
                            error =
                                auth.keyError ?? 'Unable to create. Try again.';
                          });
                        }
                      },
                child: AppText(saving ? 'Creating…' : 'Create key'),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), name.dispose);
    if (!mounted || issued == null || api.identity != identity) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const AppText('Save your personal key'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText(
              'This secret is shown once. Save it securely; it will not appear in your key list.',
            ),
            const SizedBox(height: 16),
            Consumer<ApiService>(
              builder: (ctx, session, _) => session.identity == identity
                  ? SelectableText(issued!)
                  : const AppText('The account has changed. Close this form.'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (api.identity != identity) return;
              try {
                await _copy(issued!);
              } catch (_) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: AppText(
                        'Unable to copy. Select the code to copy it.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const AppText('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const AppText('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(HeritageKey key) async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();
    final identity = api.identity;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText('Revoke “${key.name}”?'),
        content: const AppText(
          'This key will no longer allow new sign-ins. Existing sessions remain active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AppText('Revoke'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted && identity == api.identity) {
      await auth.revokeHeritageKey(key.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isPreviewMode) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AppText('Explore mode: sign in to manage your personal keys.'),
        ),
      );
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: auth.fetchHeritageKeys,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            AppText(
              'Personal keys',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const AppText(
              'A key opens your account with the same permissions as your password. Keep it private. Revoke a lost key below.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: auth.isSavingKey ? null : _generate,
              icon: const Icon(Icons.add),
              label: const AppText('Create a personal key'),
            ),
            if (auth.isLoadingKeys)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (auth.keyError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: AppText(
                          auth.keyError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: auth.isLoadingKeys
                            ? null
                            : auth.fetchHeritageKeys,
                        child: const AppText('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            if (!auth.isLoadingKeys &&
                auth.heritageKeys.isEmpty &&
                auth.keyError == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: AppText(
                  'No personal keys yet. Create one to sign in without typing your password.',
                ),
              ),
            for (final key in auth.heritageKeys) _card(key, auth),
          ],
        ),
      ),
    );
  }

  Widget _card(HeritageKey key, AuthProvider auth) {
    final expired =
        key.expiresAt != null && !key.expiresAt!.isAfter(DateTime.now());
    final usable = key.isActive && !expired;
    final status = !key.isActive
        ? 'Revoked'
        : expired
        ? 'Expired'
        : 'Active';
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(key.name, style: Theme.of(context).textTheme.titleMedium),
                Chip(
                  label: AppText(status),
                  avatar: Icon(usable ? Icons.key : Icons.key_off, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              context.tr('Secret hidden. Create a replacement if needed.'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            AppText('${key.roleDisplay} · ${key.usageCount} uses'),
            if (key.expiresAt != null)
              AppText(
                'Expiration: ${key.expiresAt!.toLocal().toString().split('.').first}',
              ),
            Wrap(
              spacing: 8,
              children: [
                if (key.isActive)
                  TextButton.icon(
                    onPressed: auth.isRevokingKey(key.id)
                        ? null
                        : () => _revoke(key),
                    icon: const Icon(Icons.key_off),
                    label: AppText(
                      auth.isRevokingKey(key.id) ? 'Revoking…' : 'Revoke',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
