import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/royal_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tree_provider.dart';
import 'royal_button.dart';

class HeritageKeySheet extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const HeritageKeySheet({super.key, required this.onLoginSuccess});

  static void show(BuildContext context, {VoidCallback? onLoginSuccess}) {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);

    void handleSuccess() {
      Navigator.of(context).pop();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      treeProvider.loadData(
        targetTreeId: auth.invitedTreeId,
        targetPersonId: auth.invitedPersonId,
      );
      if (onLoginSuccess != null) {
        onLoginSuccess();
      }
    }

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: HeritageKeySheet(onLoginSuccess: handleSuccess),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: HeritageKeySheet(onLoginSuccess: handleSuccess),
          ),
        ),
      );
    }
  }

  @override
  State<HeritageKeySheet> createState() => _HeritageKeySheetState();
}

class _HeritageKeySheetState extends State<HeritageKeySheet> {
  final _keyController = TextEditingController(text: 'KKEVO-ROYAL-2026-ROOT');
  final _formKey = GlobalKey<FormState>();
  String? _localError;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _keyController.text = data.text!.trim().toUpperCase();
        _localError = null;
      });
    }
  }

  void _applyPresetKey(String key) {
    setState(() {
      _keyController.text = key;
      _localError = null;
    });
  }

  Future<void> _handleHeritageLogin() async {
    final key = _keyController.text.trim().toUpperCase();
    if (key.isEmpty) {
      setState(() {
        _localError = 'Please enter a valid Heritage Passkey.';
      });
      return;
    }

    setState(() {
      _localError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.loginWithHeritageKey(key);

    if (success) {
      if (mounted) {
        widget.onLoginSuccess();
      }
    } else {
      setState(() {
        _localError = auth.errorMessage ?? 'Invalid Heritage Key. Please check the key and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12141D) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: RoyalTheme.brightGold.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.15),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Pill
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // Royal Medallion Shield
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B), Color(0xFF6B4E00)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: RoyalTheme.brightGold.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.key_rounded,
                    color: Colors.black,
                    size: 34,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Unlock Dynasty Vault',
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? RoyalTheme.lightGold : const Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Enter your sacred Heritage Passkey for instant passwordless lineage access',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 20),

              // Error Display
              if (_localError != null || auth.errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localError ?? auth.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Key Input Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HERITAGE PASSKEY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: RoyalTheme.brightGold,
                    ),
                  ),
                  InkWell(
                    onTap: _pasteFromClipboard,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.content_paste_rounded, size: 13, color: RoyalTheme.brightGold),
                          const SizedBox(width: 4),
                          Text(
                            'Paste',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RoyalTheme.brightGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _keyController,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. KKEVO-ROYAL-2026-ROOT',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    letterSpacing: 0.5,
                  ),
                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: RoyalTheme.brightGold, size: 20),
                  suffixIcon: _keyController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                          onPressed: () => setState(() => _keyController.clear()),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0B0D13) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: RoyalTheme.brightGold.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: RoyalTheme.brightGold.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: RoyalTheme.brightGold, width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (_localError != null) setState(() => _localError = null);
                },
              ),

              const SizedBox(height: 18),

              // Quick Preset Key Chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Clés d\'Accès Immédiat (PostgreSQL Authentifié)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetPill(
                      label: '👑 Curateur',
                      sub: '2026-ROOT',
                      keyStr: 'KKEVO-ROYAL-2026-ROOT',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetPill(
                      label: '🛡️ Sages',
                      sub: 'ELDER-7777',
                      keyStr: 'KKEVO-ELDER-7777',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPresetPill(
                      label: '🌱 Membre',
                      sub: 'N9AH-FYAJ',
                      keyStr: 'KKEVO-ROYAL-N9AH-FYAJ',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Unlock CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: RoyalButton(
                  label: 'Unlock Dynasty Vault',
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                        )
                      : const Icon(Icons.lock_open_rounded, color: Colors.black, size: 20),
                  variant: RoyalButtonVariant.gold,
                  fontSize: 15,
                  onPressed: auth.isLoading ? null : _handleHeritageLogin,
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Dismiss',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetPill({
    required String label,
    required String sub,
    required String keyStr,
    required bool isDark,
  }) {
    final isSelected = _keyController.text.trim() == keyStr;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _applyPresetKey(keyStr);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? RoyalTheme.brightGold.withValues(alpha: 0.16)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? RoyalTheme.brightGold
                : RoyalTheme.brightGold.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? RoyalTheme.brightGold : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
