import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/royal_theme.dart';
import '../providers/tree_provider.dart';
import '../providers/auth_provider.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ServerSettingsDialog(),
    );
  }

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final current = ApiConfig.baseUrl;
    _controller = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String urlStr) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    var testUrl = urlStr.trim().replaceAll(RegExp(r'/+$'), '');
    if (!testUrl.startsWith('http://') && !testUrl.startsWith('https://')) {
      testUrl = 'http://$testUrl';
    }

    try {
      testUrl = ApiConfig.normalizeBaseUrl(testUrl);
      final res = await http
          .get(Uri.parse('$testUrl/health/'))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200 &&
          jsonDecode(res.body)['service'] == 'familytree') {
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = 'Connected to the server (status ${res.statusCode})';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Server error (status ${res.statusCode})';
        });
      }
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult =
            'Enter a valid server address without credentials, a query or a fragment.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult =
            'Unable to reach the server.\nCheck that the PC and phone are on the same Wi-Fi network.';
      });
    }
  }

  Future<void> _saveAndApply() async {
    var clean = _controller.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty) return;

    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    try {
      clean = ApiConfig.normalizeBaseUrl(clean);
    } on FormatException {
      setState(
        () => _testResult =
            'Enter a valid server address without credentials, a query or a fragment.',
      );
      return;
    }

    if (clean != ApiConfig.baseUrl) await context.read<AuthProvider>().logout();
    if (!mounted) return;
    await ApiConfig.setBaseUrl(clean);
    if (mounted) {
      final tree = Provider.of<TreeProvider>(context, listen: false);
      tree.loadData();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText('Server configured: $clean'),
          backgroundColor: const Color(0xFF1B6B38),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF131622) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: RoyalTheme.borderDark, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: RoyalTheme.brightGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      color: RoyalTheme.brightGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Server connection',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? RoyalTheme.lightGold
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        AppText(
                          'Connect your phone without a cable',
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
              const SizedBox(height: 18),

              AppText(
                'Server address',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                style: GoogleFonts.jetBrainsMono(fontSize: 13),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.dns_outlined,
                    color: RoyalTheme.brightGold,
                    size: 18,
                  ),
                  hintText: context.tr('http://10.172.30.60:8000/api'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: RoyalTheme.borderDark),
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

              AppText(
                'Suggested addresses',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const AppText(
                      'Wi-Fi PC (10.172.30.60)',
                      style: TextStyle(fontSize: 11),
                    ),
                    avatar: const Icon(
                      Icons.wifi,
                      size: 14,
                      color: RoyalTheme.brightGold,
                    ),
                    onPressed: () {
                      _controller.text = 'http://10.172.30.60:8000/api';
                      _testConnection(_controller.text);
                    },
                  ),
                  ActionChip(
                    label: const AppText(
                      'Wi-Fi (192.168.1.74)',
                      style: TextStyle(fontSize: 11),
                    ),
                    avatar: const Icon(
                      Icons.home,
                      size: 14,
                      color: RoyalTheme.brightGold,
                    ),
                    onPressed: () {
                      _controller.text = 'http://192.168.1.74:8000/api';
                      _testConnection(_controller.text);
                    },
                  ),
                  ActionChip(
                    label: const AppText(
                      'USB cable / ADB (127.0.0.1)',
                      style: TextStyle(fontSize: 11),
                    ),
                    avatar: const Icon(
                      Icons.usb,
                      size: 14,
                      color: RoyalTheme.brightGold,
                    ),
                    onPressed: () {
                      _controller.text = 'http://127.0.0.1:8000/api';
                      _testConnection(_controller.text);
                    },
                  ),
                  ActionChip(
                    label: const AppText(
                      'Emulator (10.0.2.2)',
                      style: TextStyle(fontSize: 11),
                    ),
                    avatar: const Icon(
                      Icons.phone_android,
                      size: 14,
                      color: RoyalTheme.brightGold,
                    ),
                    onPressed: () {
                      _controller.text = 'http://10.0.2.2:8000/api';
                      _testConnection(_controller.text);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (_testResult != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? const Color(0xFF1B6B38).withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _testSuccess
                          ? const Color(0xFF22C55E)
                          : Colors.redAccent,
                    ),
                  ),
                  child: AppText(
                    _testResult!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _testSuccess
                          ? const Color(0xFF22C55E)
                          : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isTesting
                          ? null
                          : () => _testConnection(_controller.text),
                      child: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const AppText(
                              'Test connection',
                              style: TextStyle(fontSize: 13),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoyalTheme.brightGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveAndApply,
                      child: const AppText(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
