import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../services/api_service.dart';
import '../../widgets/kkevo_ui.dart';

class RecoveryView extends StatefulWidget {
  const RecoveryView({super.key});
  @override
  State<RecoveryView> createState() => _RecoveryViewState();
}

class _RecoveryViewState extends State<RecoveryView> {
  final _email = TextEditingController(),
      _code = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _sent = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final api = context.read<ApiService>();
    final identity = api.identity;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await api.recoverAccount(
      _sent
          ? {
              'action': 'confirm',
              'code': _code.text.trim(),
              'new_password': _password.text,
            }
          : {'action': 'request', 'email': _email.text.trim()},
    );
    if (!mounted) return;
    if (api.identity != identity) {
      setState(() {
        _busy = false;
        _error = 'The account has changed. Close this form.';
      });
      return;
    }
    setState(() {
      _busy = false;
      _error = result == null
          ? api.lastError ?? 'Unable to complete this action.'
          : null;
    });
    if (result == null) return;
    if (_sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Password reset. Sign in with your new password.'),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const AppText('Recover my account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const KkevoIcon(Icons.lock_reset_rounded, size: 64),
            const SizedBox(height: 20),
            AppText(
              _sent ? 'Check your email' : 'Forgot your password?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const AppText(
              'Recovery is available after verifying your account email. Personal login keys can also sign in to your account.',
            ),
            const SizedBox(height: 20),
            Form(
              key: _form,
              child: Column(
                children: [
                  if (!_sent)
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: context.tr('Account email'),
                      ),
                      validator: localizeValidator(
                        context,
                        (v) =>
                            v != null &&
                                RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(v.trim())
                            ? null
                            : 'Enter a valid email address.',
                      ),
                    ),
                  if (_sent) ...[
                    const AppText(
                      'If this is a verified account, a recovery code will be sent to its email.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _code,
                      enabled: !_busy,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: context.tr('Email code'),
                      ),
                      validator: localizeValidator(
                        context,
                        (v) => v == null || v.trim().isEmpty
                            ? 'Enter the code from your email.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: context.tr('New password'),
                      ),
                      validator: localizeValidator(
                        context,
                        (v) => v == null || v.isEmpty
                            ? 'Enter a new password.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      enabled: !_busy,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Confirm new password'),
                      ),
                      validator: localizeValidator(
                        context,
                        (v) => v != _password.text
                            ? 'Passwords must match.'
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Semantics(
                  liveRegion: true,
                  child: AppText(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            KkevoButton(
              label: _sent ? 'Reset password' : 'Send recovery code',
              busy: _busy,
              onPressed: _busy ? null : _submit,
            ),
            if (_sent)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _sent = false;
                        _error = null;
                      }),
                child: const AppText('Request a new code'),
              ),
          ],
        ),
      ),
    ),
  );
}
