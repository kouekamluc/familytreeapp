import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';

class AccountSwitcherSheet extends StatelessWidget {
  final VoidCallback? onAddNewAccount;

  const AccountSwitcherSheet({super.key, this.onAddNewAccount});

  static void show(BuildContext context, {VoidCallback? onAddNewAccount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AccountSwitcherSheet(onAddNewAccount: onAddNewAccount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tree = Provider.of<TreeProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saved = auth.savedAccounts;
    final currentUsername = auth.currentUser?.username;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: RoyalTheme.brightGold.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RoyalTheme.brightGold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.switch_account_rounded, color: RoyalTheme.brightGold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Changer de Compte',
                      style: GoogleFonts.cinzel(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? RoyalTheme.lightGold : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Basculez entre vos différents profils dynastiques',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (saved.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucun autre compte enregistré sur cet appareil.',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: saved.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final acc = saved[index];
                final isActive = currentUsername != null &&
                    acc.username.toLowerCase() == currentUsername.toLowerCase();

                return InkWell(
                  onTap: () async {
                    if (isActive) {
                      Navigator.pop(context);
                      return;
                    }
                    Navigator.pop(context);
                    final success = await auth.switchToAccount(acc);
                    if (success) {
                      await tree.loadData();
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? RoyalTheme.brightGold.withValues(alpha: isDark ? 0.2 : 0.14)
                          : (isDark ? const Color(0xFF171A26) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive
                            ? RoyalTheme.brightGold
                            : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isActive ? RoyalTheme.brightGold : Colors.grey[800],
                          child: Text(
                            (acc.displayName.isNotEmpty ? acc.displayName[0] : 'U').toUpperCase(),
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      acc.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Actif',
                                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                acc.heritageKey != null
                                    ? 'Clé : ${acc.heritageKey!.substring(0, acc.heritageKey!.length > 10 ? 10 : acc.heritageKey!.length)}...'
                                    : '@${acc.username} • ${acc.role ?? "Membre"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                          tooltip: 'Oublier ce compte',
                          onPressed: () => auth.removeSavedAccount(acc.username),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: RoyalTheme.brightGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text(
              'Connexion à un autre compte',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (onAddNewAccount != null) {
                onAddNewAccount!();
              } else {
                auth.logout();
                tree.clearData();
              }
            },
          ),
        ],
      ),
    );
  }
}
