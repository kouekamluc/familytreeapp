import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../providers/tree_provider.dart';
import '../services/api_service.dart';

class TreeManagerSheet extends StatelessWidget {
  const TreeManagerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TreeManagerSheet(),
    );
  }

  void _showCreateTreeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF131722)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: RoyalTheme.brightGold, width: 1.2),
          ),
          title: Text(
            'Créer une Nouvelle Dynastie',
            style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de la Famille / Arbre *',
                  hintText: 'ex. Dynastie Kouekam',
                  prefixIcon: Icon(Icons.account_tree_outlined, color: RoyalTheme.brightGold),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description coutumière / Chefferie',
                  hintText: 'ex. Branche des Hauts Plateaux',
                  prefixIcon: Icon(Icons.description_outlined, color: RoyalTheme.brightGold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: RoyalTheme.brightGold),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setDlgState(() => isSaving = true);
                      final tree = await Provider.of<TreeProvider>(context, listen: false)
                          .createTree(name, descCtrl.text.trim());
                      if (tree != null) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dynastie "${tree.name}" créée avec succès.')),
                          );
                        }
                      } else {
                        setDlgState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text('Échec de la création. Vérifiez la connexion.'),
                            ),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Créer l\'Arbre', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, int? treeId) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Génération de l\'archive d\'exportation en cours...')));
    final data = await ApiService().exportTreeData(treeId: treeId);
    if (data == null) {
      scaffold.showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Échec de l\'exportation des données.')),
      );
      return;
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Exportation Dynastique (JSON)', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arbres : ${(data['family_trees'] as List?)?.length ?? 0} | '
                'Membres : ${(data['people'] as List?)?.length ?? 0} | '
                'Alliances : ${(data['relationships'] as List?)?.length ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                height: 160,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonStr,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données JSON copiées dans le presse-papiers !')),
              );
            },
            child: const Text('Copier JSON'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RoyalTheme.brightGold),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    bool isImporting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Importer des Données (JSON)', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Collez le contenu JSON complet d\'un export dynastique :',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textCtrl,
                maxLines: 6,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '{\n  "people": [...],\n  "relationships": [...]\n}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: RoyalTheme.brightGold),
              onPressed: isImporting
                  ? null
                  : () async {
                      try {
                        final parsed = jsonDecode(textCtrl.text.trim()) as Map<String, dynamic>;
                        setDlgState(() => isImporting = true);
                        final ok = await ApiService().importTreeData(parsed);
                        if (ok) {
                          if (context.mounted) {
                            await Provider.of<TreeProvider>(context, listen: false).loadData();
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Données importées avec succès !')),
                            );
                          }
                        } else {
                          setDlgState(() => isImporting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text('Échec de l\'importation. Vérifiez le format JSON.'),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setDlgState(() => isImporting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text('Format JSON invalide : $e'),
                            ),
                          );
                        }
                      }
                    },
              child: isImporting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Importer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeProvider = Provider.of<TreeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trees = treeProvider.trees;
    final selected = treeProvider.selectedTree;

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
                  color: RoyalTheme.brightGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_tree_rounded, color: RoyalTheme.brightGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dynasties & Arbres Familiaux',
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Basculez entre différentes lignées ou créez-en une nouvelle',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Trees List
          if (trees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aucun arbre généalogique trouvé.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: trees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final t = trees[idx];
                  final isCurrent = selected?.id == t.id;

                  return InkWell(
                    onTap: () {
                      treeProvider.selectTree(t);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? RoyalTheme.brightGold.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF191D2C) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent
                              ? RoyalTheme.brightGold
                              : RoyalTheme.borderDark.withValues(alpha: 0.4),
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isCurrent ? RoyalTheme.brightGold : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: isCurrent ? RoyalTheme.brightGold : null,
                                  ),
                                ),
                                if (t.description.isNotEmpty)
                                  Text(
                                    t.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Action 1: Create New Tree
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, color: Colors.black, size: 18),
            label: const Text(
              'Créer une Nouvelle Dynastie / Arbre',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: RoyalTheme.brightGold,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showCreateTreeDialog(context);
            },
          ),

          const SizedBox(height: 10),

          // Actions 2: Export & Import
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 16, color: RoyalTheme.brightGold),
                  label: const Text(
                    'Exporter (JSON)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: RoyalTheme.brightGold),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showExportDialog(context, selected?.id),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload_rounded, size: 16, color: RoyalTheme.brightGold),
                  label: const Text(
                    'Importer (JSON)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoyalTheme.brightGold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: RoyalTheme.brightGold),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showImportDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
