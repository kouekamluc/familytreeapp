import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/royal_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tree_provider.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/royal_card.dart';
import '../../widgets/server_settings_dialog.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginView({super.key, required this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _useHeritageKey = true;
  final _formKey = GlobalKey<FormState>();
  final _keyFormKey = GlobalKey<FormState>();

  final _heritageKeyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _heritageKeyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleHeritageKeyLogin() async {
    final key = _heritageKeyController.text.trim().toUpperCase();
    if (key.isEmpty) return;

    HapticFeedback.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tree = Provider.of<TreeProvider>(context, listen: false);
    final success = await auth.loginWithHeritageKey(key);
    if (success) {
      await tree.loadData(
        targetTreeId: auth.invitedTreeId,
        targetPersonId: auth.invitedPersonId,
      );
      if (mounted) {
        widget.onLoginSuccess();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF8A1C14),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    auth.errorMessage ?? 'Clé d\'Héritage invalide ou expirée.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tree = Provider.of<TreeProvider>(context, listen: false);
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
    if (success) {
      await tree.loadData(
        targetTreeId: auth.invitedTreeId,
        targetPersonId: auth.invitedPersonId,
      );
      if (mounted) {
        widget.onLoginSuccess();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF8A1C14),
            content: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    auth.errorMessage ??
                        'Identifiants invalides. Veuillez vérifier vos accès.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDemoLogin() async {
    HapticFeedback.lightImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tree = Provider.of<TreeProvider>(context, listen: false);
    await auth.demoLogin();
    await tree.loadData(
      targetTreeId: auth.invitedTreeId,
      targetPersonId: auth.invitedPersonId,
    );
    if (mounted) {
      widget.onLoginSuccess();
    }
  }

  Future<void> _handleSwitchAccount(SavedAccount account) async {
    HapticFeedback.selectionClick();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tree = Provider.of<TreeProvider>(context, listen: false);
    final success = await auth.switchToAccount(account);
    if (success) {
      await tree.loadData();
      if (mounted) widget.onLoginSuccess();
    }
  }

  Future<void> _handleOpenOfflineArchive() async {
    HapticFeedback.lightImpact();
    final tree = Provider.of<TreeProvider>(context, listen: false);
    await tree.loadData();
    if (mounted) widget.onLoginSuccess();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _heritageKeyController.text = data.text!.trim().toUpperCase();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: RoyalCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Medallion Crest
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF141722)
                          : const Color(0xFFF9F5EC),
                      border: Border.all(
                        color: RoyalTheme.brightGold,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: RoyalTheme.brightGold.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Royal Sanctuary',
                    style: GoogleFonts.cinzel(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark
                          ? RoyalTheme.lightGold
                          : const Color(0xFF1C1917),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Authenticate to curate the lineage archive',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Saved Accounts Quick-Login (if previously logged in on this device)
                  if (auth.savedAccounts.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'COMPTES ENREGISTRÉS SUR CET APPAREIL',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: RoyalTheme.brightGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: auth.savedAccounts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final acc = auth.savedAccounts[idx];
                          return ActionChip(
                            avatar: CircleAvatar(
                              radius: 12,
                              backgroundColor: RoyalTheme.brightGold,
                              child: Text(
                                (acc.displayName.isNotEmpty ? acc.displayName[0] : 'U').toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                            label: Text(
                              acc.displayName,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: isDark ? const Color(0xFF191D2C) : const Color(0xFFF1F5F9),
                            side: const BorderSide(color: RoyalTheme.borderDark),
                            onPressed: () => _handleSwitchAccount(acc),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Mode Selector Tabs (Heritage Key vs Password)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F1118)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: RoyalTheme.brightGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _useHeritageKey = true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: _useHeritageKey
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFB8860B),
                                          Color(0xFFFFD700),
                                          Color(0xFFC5A059),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.key_rounded,
                                    size: 16,
                                    color: _useHeritageKey
                                        ? Colors.black
                                        : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[700]),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Heritage Key',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _useHeritageKey
                                          ? Colors.black
                                          : (isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _useHeritageKey = false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: !_useHeritageKey
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFB8860B),
                                          Color(0xFFFFD700),
                                          Color(0xFFC5A059),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: !_useHeritageKey
                                        ? Colors.black
                                        : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[700]),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Password',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: !_useHeritageKey
                                          ? Colors.black
                                          : (isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (auth.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // TAB A: HERITAGE KEY FORM
                  if (_useHeritageKey) ...[
                    Form(
                      key: _keyFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SACRED PASSKEY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: RoyalTheme.brightGold,
                                ),
                              ),
                              InkWell(
                                onTap: _pasteFromClipboard,
                                child: const Text(
                                  '📋 Paste',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: RoyalTheme.brightGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _heritageKeyController,
                            textCapitalization: TextCapitalization.characters,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.vpn_key_rounded,
                                color: RoyalTheme.brightGold,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: RoyalTheme.brightGold.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: RoyalTheme.brightGold,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RoyalTheme.brightGold,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: auth.isLoading
                                  ? null
                                  : _handleHeritageKeyLogin,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Unlock with Heritage Key',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                  // TAB B: PASSWORD FORM
                  else ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: RoyalTheme.brightGold,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: RoyalTheme.borderDark,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: RoyalTheme.brightGold,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Please enter username'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: RoyalTheme.brightGold,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: RoyalTheme.borderDark,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: RoyalTheme.brightGold,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Please enter password'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RoyalTheme.brightGold,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: auth.isLoading ? null : _handleLogin,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In to Dynasty',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.flash_on, color: RoyalTheme.brightGold, size: 18),
                      label: const Text(
                        'Explorer un exemple (lecture seule)',
                        style: TextStyle(
                          color: RoyalTheme.brightGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: RoyalTheme.brightGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: auth.isLoading ? null : _handleDemoLogin,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Open Phone Offline Archive directly
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: TextButton.icon(
                      icon: const Icon(Icons.phone_android_rounded, size: 16, color: RoyalTheme.brightGold),
                      label: const Text(
                        'Ouvrir les archives locales du téléphone',
                        style: TextStyle(color: RoyalTheme.brightGold, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _handleOpenOfflineArchive,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Configure Wi-Fi IP for non-cable connectivity
                  TextButton.icon(
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 15, color: Colors.grey),
                    label: const Text(
                      'Configurer l\'IP Serveur (Wi-Fi sans câble)',
                      style: TextStyle(color: Colors.grey, fontSize: 11.5),
                    ),
                    onPressed: () => ServerSettingsDialog.show(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
