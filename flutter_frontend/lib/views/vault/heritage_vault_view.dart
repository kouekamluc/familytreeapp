import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../models/heritage_key.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/royal_button.dart';

class HeritageVaultView extends StatefulWidget {
  const HeritageVaultView({super.key});

  @override
  State<HeritageVaultView> createState() => _HeritageVaultViewState();
}

class _HeritageVaultViewState extends State<HeritageVaultView> {
  String? _copiedKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchHeritageKeys();
    });
  }

  void _copyToClipboard(String key) {
    Clipboard.setData(ClipboardData(text: key));
    HapticFeedback.mediumImpact();
    setState(() => _copiedKey = key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E212B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: RoyalTheme.brightGold, width: 1),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: RoyalTheme.brightGold,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clé personnelle copiée. Ne la partagez pas.',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copiedKey = null);
    });
  }

  void _showGenerateKeyModal() {
    final nameCtrl = TextEditingController(text: 'Nouvelle Clé de Famille');
    String selectedRole = 'FAMILY_MEMBER';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 10,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RoyalTheme.brightGold.withValues(alpha: 0.15),
                        border: Border.all(
                          color: RoyalTheme.brightGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: RoyalTheme.brightGold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Générer une Clé d\'Héritage',
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? RoyalTheme.lightGold
                                  : const Color(0xFF1C1917),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Accès sécurisé sans mot de passe pour la famille',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'INTITULÉ DE LA CLÉ',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: RoyalTheme.brightGold,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ex: Branche Jean Kkevo - Douala',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B0D13)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: RoyalTheme.brightGold,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'RÔLE ATTRIBUÉ',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: RoyalTheme.brightGold,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B0D13)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: RoyalTheme.brightGold,
                        width: 2,
                      ),
                    ),
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1A1C26)
                      : Colors.white,
                  items: const [
                    DropdownMenuItem(
                      value: 'FAMILY_MEMBER',
                      child: Text(
                        '👤 Membre de la Famille (Consultation)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ROYAL_PATRIARCH',
                      child: Text(
                        '🏛️ Patriarche / Ancien (Sagesse)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'CURATOR',
                      child: Text(
                        '👑 Curateur / Administrateur (Gestion)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: RoyalButton(
                    label: 'Créer la Clé',
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                    variant: RoyalButtonVariant.gold,
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final created = await auth.generateHeritageKey(
                        name: nameCtrl.text.trim().isEmpty
                            ? 'Clé Royale'
                            : nameCtrl.text.trim(),
                        role: selectedRole,
                      );
                      if (created != null && mounted) {
                        _copyToClipboard(created.key);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = auth.heritageKeys;

    // Primary active key
    if (auth.isPreviewMode) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Mode découverte : les clés personnelles sont disponibles après connexion.',
            ),
          ),
        ),
      );
    }
    final usableKeys = keys
        .where(
          (k) =>
              k.isActive &&
              (k.expiresAt == null || k.expiresAt!.isAfter(DateTime.now())),
        )
        .toList();
    final HeritageKey? activeKey = usableKeys.isEmpty ? null : usableKeys.first;

    return Scaffold(
      body: RefreshIndicator(
        color: RoyalTheme.brightGold,
        backgroundColor: isDark ? const Color(0xFF141722) : Colors.white,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await auth.fetchHeritageKeys();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Banner Card
            if (activeKey != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF202330), const Color(0xFF11131A)]
                        : [const Color(0xFFFFFDF8), const Color(0xFFF3EDE2)],
                  ),
                  border: Border.all(
                    color: RoyalTheme.brightGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: RoyalTheme.brightGold.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RoyalTheme.brightGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activeKey.roleDisplay.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3.5,
                                backgroundColor: Colors.greenAccent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Active & Valide',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      activeKey.name,
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? RoyalTheme.lightGold
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // The Key Token Badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: RoyalTheme.brightGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              activeKey.key,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: RoyalTheme.brightGold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _copiedKey == activeKey.key
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              color: RoyalTheme.brightGold,
                              size: 20,
                            ),
                            tooltip: 'Copier la clé',
                            onPressed: () => _copyToClipboard(activeKey.key),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Utilisée ${activeKey.usageCount} fois',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const Flexible(
                          child: Text(
                            'Clé personnelle : ne la partagez pas.',
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Header for Registered Keys
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'CLÉS ENREGISTRÉES (${keys.length})',
                    style: GoogleFonts.cinzel(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: isDark
                          ? RoyalTheme.lightGold
                          : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showGenerateKeyModal,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: RoyalTheme.brightGold,
                  ),
                  label: Text(
                    'Nouvelle Clé',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: RoyalTheme.brightGold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (auth.isLoadingKeys)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    color: RoyalTheme.brightGold,
                  ),
                ),
              )
            else if (keys.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.key_off_outlined,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune clé active.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...keys.map((k) => _buildKeyCard(k, isDark, auth)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RoyalTheme.brightGold,
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'Créer Clé',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showGenerateKeyModal();
        },
      ),
    );
  }

  Widget _buildKeyCard(HeritageKey keyItem, bool isDark, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151822) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: keyItem.isActive
              ? RoyalTheme.brightGold.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    keyItem.isActive
                        ? Icons.vpn_key_rounded
                        : Icons.key_off_rounded,
                    color: keyItem.isActive
                        ? RoyalTheme.brightGold
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    keyItem.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: keyItem.isActive
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  keyItem.isActive ? 'Active' : 'Révoquée',
                  style: TextStyle(
                    color: keyItem.isActive
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    keyItem.key,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(keyItem.key),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _copiedKey == keyItem.key
                          ? Icons.check_circle_rounded
                          : Icons.copy_rounded,
                      size: 16,
                      color: RoyalTheme.brightGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${keyItem.roleDisplay} • ${keyItem.usageCount} utilisations',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (keyItem.isActive)
                TextButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark
                            ? const Color(0xFF1A1C26)
                            : Colors.white,
                        title: const Text('Révoquer cette clé ?'),
                        content: Text(
                          'Cette clé personnelle ne permettra plus de vous connecter.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Révoquer',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await auth.revokeHeritageKey(keyItem.id);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Désactiver',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
