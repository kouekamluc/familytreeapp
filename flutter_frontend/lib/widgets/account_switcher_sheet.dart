import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';
import '../views/auth/login_view.dart';

class AccountSwitcherSheet extends StatelessWidget {
  final VoidCallback? onAddNewAccount;
  const AccountSwitcherSheet({super.key, this.onAddNewAccount});
  static void show(BuildContext context, {VoidCallback? onAddNewAccount}) {
    context.read<AuthProvider>().loadSavedAccounts();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AccountSwitcherSheet(onAddNewAccount: onAddNewAccount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tree = context.read<TreeProvider>();
    final rootContext = Navigator.of(context).context;
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
            'Switch accounts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const AppText(
            'Accounts and their records are kept separate on this device.',
          ),
          if (auth.isLoading) const LinearProgressIndicator(),
          if (auth.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Semantics(
                liveRegion: true,
                child: AppText(
                  auth.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          if (auth.savedAccounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: AppText('No saved accounts.'),
            ),
          for (final account in auth.savedAccounts)
            ListTile(
              selected: account.userId == auth.currentUser?.id,
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(account.displayName),
              subtitle: AppText(
                '@${account.username}${account.userId == auth.currentUser?.id ? ' · Current account' : ''}',
              ),
              onTap: auth.isLoading
                  ? null
                  : () async {
                      if (account.userId == auth.currentUser?.id) {
                        Navigator.pop(context);
                        return;
                      }
                      final ok = await auth.switchToAccount(account);
                      if (ok) {
                        await tree.loadData();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
              trailing: IconButton(
                tooltip: context.tr('Forget this account'),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final current = account.userId == auth.currentUser?.id;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const AppText('Forget this account?'),
                            content: AppText(
                              current
                                  ? 'You will be signed out and this account’s local records will be removed from this device.'
                                  : 'Its credentials and local records will be removed from this device. Records on the server will be kept.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const AppText('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const AppText('Forget'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          if (current) await auth.logout();
                          await auth.removeSavedAccount(account.username);
                        }
                      },
                icon: const Icon(Icons.close),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: auth.isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    if (onAddNewAccount != null) {
                      onAddNewAccount!();
                      return;
                    }
                    showDialog(
                      context: rootContext,
                      builder: (ctx) => Dialog(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 520,
                            maxHeight:
                                MediaQuery.sizeOf(rootContext).height * .9,
                          ),
                          child: LoginView(
                            onLoginSuccess: () {
                              Navigator.pop(ctx);
                              tree.loadData(
                                targetTreeId: auth.invitedTreeId,
                                targetPersonId: auth.invitedPersonId,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.person_add_outlined),
            label: const AppText('Sign in to another account'),
          ),
        ],
      ),
    );
  }
}
