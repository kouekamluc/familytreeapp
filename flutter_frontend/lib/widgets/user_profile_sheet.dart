import '../views/auth/account_settings_view.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/theme_provider.dart';
import 'language_sheet.dart';
import 'account_switcher_sheet.dart';
import 'server_settings_dialog.dart';
import '../views/family_connections_view.dart';

class UserProfileSheet extends StatelessWidget {
  final VoidCallback? onOpenTree, onOpenVault, onSignOut;
  const UserProfileSheet({
    super.key,
    this.onOpenTree,
    this.onOpenVault,
    this.onSignOut,
  });
  static void show(
    BuildContext context, {
    VoidCallback? onOpenTree,
    VoidCallback? onOpenVault,
    VoidCallback? onSignOut,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => UserProfileSheet(
      onOpenTree: onOpenTree,
      onOpenVault: onOpenVault,
      onSignOut: onSignOut,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tree = context.watch<TreeProvider>();
    final access = context.watch<AccessibilityProvider>();
    final theme = context.watch<ThemeProvider>();
    final rootContext = Navigator.of(context).context;
    final focus = tree.focusPerson;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        children: [
          Text(
            auth.isPreviewMode
                ? context.tr('Explore mode')
                : auth.currentUser?.displayName ?? context.tr('My account'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (!auth.isPreviewMode)
            AppText('@${auth.currentUser?.username ?? ''}'),
          if (auth.currentUser?.email.isNotEmpty == true)
            Text(auth.currentUser!.email),
          const SizedBox(height: 20),
          AppText(
            'Tree display',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RadioGroup<TreeScope>(
            groupValue: tree.treeScope,
            onChanged: (v) {
              if (v != null) tree.setTreeScope(v);
            },
            child: const Column(
              children: [
                RadioListTile<TreeScope>(
                  value: TreeScope.extendedDynasty,
                  title: AppText('Whole family'),
                  subtitle: AppText('All recorded branches and generations.'),
                ),
                RadioListTile<TreeScope>(
                  value: TreeScope.immediateFamily,
                  title: AppText('Close family'),
                  subtitle: AppText(
                    'Parents, children, partners and siblings of the reference person.',
                  ),
                ),
              ],
            ),
          ),
          if (tree.people.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey('focus:${focus?.id}'),
              initialValue: focus?.id,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Reference person'),
              ),
              items: tree.people
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.fullName, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id != null) {
                  tree.selectPerson(tree.people.firstWhere((p) => p.id == id));
                }
              },
            ),
            const SizedBox(height: 10),
            if (focus != null)
              AppText(
                '${tree.getParentsOf(focus.id).length} parents Â· ${tree.getChildrenOf(focus.id).length} children Â· ${tree.getSiblingsOf(focus.id).length} siblings',
              ),
          ],
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const AppText('Larger text'),
            subtitle: const AppText('Easier reading'),
            value: access.isSeniorMode,
            onChanged: (_) => access.toggleSeniorMode(),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const AppText('Dark theme'),
            value: theme.isDark,
            onChanged: (_) => theme.toggleTheme(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language_rounded),
            title: const AppText('Language'),
            onTap: () => LanguageSheet.show(context),
          ),
          if (!auth.isPreviewMode)
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const AppText('Account and security'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(rootContext).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsView(),
                  ),
                );
              },
            ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_tree_outlined),
            title: const AppText('View tree'),
            enabled: onOpenTree != null,
            onTap: onOpenTree == null
                ? null
                : () {
                    Navigator.pop(context);
                    onOpenTree!();
                  },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.key),
            title: const AppText('My personal keys'),
            enabled: onOpenVault != null && !auth.isPreviewMode,
            onTap: onOpenVault == null || auth.isPreviewMode
                ? null
                : () {
                    Navigator.pop(context);
                    onOpenVault!();
                  },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.dns_outlined),
            title: const AppText('Server connection'),
            subtitle: AppText(
              tree.isOfflineMode
                  ? 'Viewing the last saved records offline'
                  : tree.errorMessage != null
                  ? 'Check your connection'
                  : auth.isPreviewMode
                  ? 'Example records'
                  : 'Server records',
            ),
            onTap: () {
              Navigator.pop(context);
              ServerSettingsDialog.show(rootContext);
            },
          ),
          if (!auth.isPreviewMode)
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const AppText('Join my family'),
              onTap: tree.isOfflineMode
                  ? null
                  : () {
                      Navigator.pop(context);
                      FamilyConnectionsView.show(rootContext);
                    },
            ),
          if (!auth.isPreviewMode)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.switch_account),
              title: const AppText('Switch accounts'),
              onTap: () {
                Navigator.pop(context);
                AccountSwitcherSheet.show(rootContext);
              },
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: AppText(
              auth.isPreviewMode ? 'Leave explore mode' : 'Sign out',
            ),
            onTap: () {
              Navigator.pop(context);
              if (onSignOut != null) {
                onSignOut!();
              } else {
                auth.logout();
              }
            },
          ),
          const SizedBox(height: 12),
          const AppText(
            'Kkevo Family Â· version 1.0.0 (1)',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
