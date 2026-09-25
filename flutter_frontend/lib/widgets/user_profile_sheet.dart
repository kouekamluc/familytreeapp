import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';
import 'account_switcher_sheet.dart';
import 'monogram_medallion.dart';
import 'royal_button.dart';
import 'server_settings_dialog.dart';

class UserProfileSheet extends StatelessWidget {
  final VoidCallback? onOpenTree;
  final VoidCallback? onOpenVault;
  final VoidCallback? onSignOut;

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
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserProfileSheet(
        onOpenTree: onOpenTree,
        onOpenVault: onOpenVault,
        onSignOut: onSignOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tree = Provider.of<TreeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final focus = tree.focusPerson;
    final people = tree.people;

    // Kin counts for focus person
    final spouseCount = focus != null ? tree.getSpousesOf(focus.id).length : 0;
    final childrenCount = focus != null ? tree.getChildrenOf(focus.id).length : 0;
    final siblingCount = focus != null ? tree.getSiblingsOf(focus.id).length : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: RoyalTheme.brightGold.withValues(alpha: isDark ? 0.6 : 0.4),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.15),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(22, 14, 22, MediaQuery.of(context).padding.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Grab Bar
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
            const SizedBox(height: 18),

            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E2435), const Color(0xFF141724)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: RoyalTheme.brightGold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  if (focus != null)
                    MonogramMedallion(person: focus, size: 64, isSelected: true)
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RoyalTheme.brightGold.withValues(alpha: 0.2),
                        border: Border.all(color: RoyalTheme.brightGold, width: 2),
                      ),
                      child: const Icon(Icons.person, color: RoyalTheme.brightGold, size: 36),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                focus?.fullName ?? auth.currentUser?.username ?? 'Dynasty Member',
                                style: GoogleFonts.cinzel(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? RoyalTheme.lightGold : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: RoyalTheme.brightGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Gen ${focus?.generationTier ?? 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (focus?.traditionalName != null && focus!.traditionalName!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            focus.traditionalName!,
                            style: GoogleFonts.cinzel(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF855B14),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              focus?.clanTotem ?? '🐆 Leopard',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${focus?.villageOfOrigin ?? 'Bandjoun'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Immediate Kin Quick Stats Ribbon
            Row(
              children: [
                Expanded(
                  child: _buildKinStatCard(
                    title: 'Époux / Épouses',
                    count: '$spouseCount',
                    icon: Icons.favorite_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKinStatCard(
                    title: 'Enfants',
                    count: '$childrenCount',
                    icon: Icons.child_care_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKinStatCard(
                    title: 'Frères / Sœurs',
                    count: '$siblingCount',
                    icon: Icons.people_outline_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tree Scope Preference (Extended Dynasty vs Immediate Family)
            Text(
              'PERSPECTIVE DE L\'ARBRE GÉNÉALOGIQUE',
              style: GoogleFonts.cinzel(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: RoyalTheme.brightGold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161A26) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                ),
              ),
              child: RadioGroup<TreeScope>(
                groupValue: tree.treeScope,
                onChanged: (val) {
                  if (val != null) tree.setTreeScope(val);
                },
                child: Column(
                  children: [
                    RadioListTile<TreeScope>(
                      value: TreeScope.extendedDynasty,
                      fillColor: WidgetStateProperty.all(RoyalTheme.brightGold),
                      title: const Text(
                        '👑 Dynastie Complète (Toute la Lignée)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Affiche les 4 générations royales et l\'ensemble des branches du clan.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                    RadioListTile<TreeScope>(
                      value: TreeScope.immediateFamily,
                      fillColor: WidgetStateProperty.all(RoyalTheme.brightGold),
                      title: Text(
                        '🏡 Ma Famille Proche (${focus?.firstName ?? "Mon Cercle Direct"})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Isole votre foyer : vous-même, vos partenaires/époux(ses), enfants, parents et fratrie.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Focus Person Selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    'MEMBRE DE RÉFÉRENCE (FOCUS)',
                    style: GoogleFonts.cinzel(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: RoyalTheme.brightGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161A26) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: focus?.id,
                  dropdownColor: isDark ? const Color(0xFF161A26) : Colors.white,
                  items: people.map((p) {
                    return DropdownMenuItem<int>(
                      value: p.id,
                      child: Text(
                        '${p.fullName} (Gen ${p.generationTier} • ${p.traditionalName ?? p.villageOfOrigin ?? ""})',
                        style: const TextStyle(fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null) {
                      tree.setFocusPersonId(newId);
                      final p = people.firstWhere((element) => element.id == newId);
                      tree.selectPerson(p);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection & Storage Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tree.isOfflineMode
                    ? const Color(0xFFB8860B).withValues(alpha: 0.15)
                    : const Color(0xFF16A34A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tree.isOfflineMode
                      ? RoyalTheme.brightGold.withValues(alpha: 0.6)
                      : const Color(0xFF22C55E).withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tree.isOfflineMode ? Icons.phone_android_rounded : Icons.cloud_done_rounded,
                    color: tree.isOfflineMode ? RoyalTheme.brightGold : const Color(0xFF22C55E),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tree.isOfflineMode
                              ? '📱 Mode Mémoire Locale Téléphone'
                              : '🌐 Synchronisé en Direct',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          tree.isOfflineMode
                              ? '${people.length} membres consultables hors-ligne sans câble'
                              : 'Connecté au serveur dynastique',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ServerSettingsDialog.show(context);
                    },
                    child: const Text('Réseau', style: TextStyle(fontSize: 11, color: RoyalTheme.brightGold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Switch Account Quick Tile
            InkWell(
              onTap: () {
                Navigator.pop(context);
                AccountSwitcherSheet.show(context);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171A26) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.switch_account_rounded, color: RoyalTheme.brightGold, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Changer de Compte',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Connectez-vous avec un autre membre ou clé',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: RoyalTheme.brightGold),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            RoyalButton(
              label: 'Afficher dans l\'Arbre Sacré',
              icon: const Icon(Icons.account_tree_rounded, color: Colors.black, size: 18),
              variant: RoyalButtonVariant.gold,
              height: 46,
              onPressed: () {
                Navigator.pop(context);
                if (onOpenTree != null) onOpenTree!();
              },
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RoyalTheme.brightGold,
                      side: const BorderSide(color: RoyalTheme.brightGold, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (onOpenVault != null) onOpenVault!();
                    },
                    icon: const Icon(Icons.vpn_key_rounded, size: 16),
                    label: const Text('Coffre-Fort', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (onSignOut != null) {
                        onSignOut!();
                      } else {
                        auth.logout();
                        tree.clearData();
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Verrouiller', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKinStatCard({
    required String title,
    required String count,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A26) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: RoyalTheme.brightGold),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RoyalTheme.brightGold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
