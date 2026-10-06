import 'recovery_view.dart';
import '../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tree_provider.dart';
import '../../widgets/kkevo_ui.dart';
import '../../widgets/server_settings_dialog.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool initialRegister;
  const LoginView({
    super.key,
    required this.onLoginSuccess,
    this.initialRegister = false,
  });
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController(),
      _password = TextEditingController(),
      _confirmation = TextEditingController(),
      _first = TextEditingController(),
      _last = TextEditingController(),
      _email = TextEditingController(),
      _key = TextEditingController();
  late bool _register;
  bool _useKey = false, _hidden = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _register = widget.initialRegister;
  }

  @override
  void dispose() {
    for (final c in [
      _username,
      _password,
      _confirmation,
      _first,
      _last,
      _email,
      _key,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading || !_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _error = null);
    final bool ok;
    if (_register) {
      ok = await auth.register(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirmation.text,
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
      );
    } else if (_useKey) {
      ok = await auth.loginWithHeritageKey(_key.text.trim().toUpperCase());
    } else {
      ok = await auth.login(_username.text.trim(), _password.text);
    }
    if (!mounted) return;
    if (ok) {
      await context.read<TreeProvider>().loadData(
        targetTreeId: auth.invitedTreeId,
        targetPersonId: auth.invitedPersonId,
      );
      if (mounted) widget.onLoginSuccess();
    } else {
      setState(
        () => _error = auth.errorMessage ?? 'Unable to sign in. Try again.',
      );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    TextInputType? type,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !context.watch<AuthProvider>().isLoading,
      keyboardType: type,
      obscureText: secret && _hidden,
      autocorrect: !secret && type != TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: controller == _username
          ? [AutofillHints.username]
          : controller == _password
          ? [AutofillHints.password]
          : null,
      decoration: InputDecoration(
        labelText: context.tr(label),
        suffixIcon: secret
            ? IconButton(
                tooltip: context.tr(
                  _hidden ? 'Show password' : 'Hide password',
                ),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
      validator: localizeValidator(
        context,
        validator ??
            (value) => value?.trim().isEmpty != false
                ? 'This field is required.'
                : null,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return PopScope(
      canPop: !auth.isLoading,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: KkevoIcon(Icons.favorite_rounded, size: 72),
                        ),
                        const SizedBox(height: 24),
                        AppText(
                          _register
                              ? 'Your story starts here.'
                              : 'Welcome back!',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        AppText(
                          _register
                              ? 'Create your own account. Then choose how to join your family.'
                              : 'Sign in to reconnect with your family.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        if (!_register) ...[
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const AppText('Password'),
                                selected: !_useKey,
                                onSelected: auth.isLoading
                                    ? null
                                    : (_) => setState(() {
                                        _useKey = false;
                                        _error = null;
                                      }),
                              ),
                              ChoiceChip(
                                label: const AppText('Personal key'),
                                selected: _useKey,
                                onSelected: auth.isLoading
                                    ? null
                                    : (_) => setState(() {
                                        _useKey = true;
                                        _error = null;
                                      }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
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
                        if (_register) ...[
                          _field(_first, 'First name'),
                          _field(_last, 'Last name'),
                          _field(
                            _email,
                            'Email address',
                            type: TextInputType.emailAddress,
                            validator: localizeValidator(
                              context,
                              (v) =>
                                  RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(v?.trim() ?? '')
                                  ? null
                                  : 'Enter a valid email address.',
                            ),
                          ),
                        ],
                        if (!_useKey || _register) ...[
                          _field(_username, 'Username'),
                          _field(
                            _password,
                            'Password',
                            secret: true,
                            validator: localizeValidator(
                              context,
                              (v) => v == null || v.isEmpty
                                  ? 'Enter your password.'
                                  : _register && v.length < 8
                                  ? 'At least 8 characters.'
                                  : null,
                            ),
                          ),
                          if (_register)
                            _field(
                              _confirmation,
                              'Confirm password',
                              secret: true,
                              validator: localizeValidator(
                                context,
                                (v) => v != _password.text
                                    ? 'Passwords do not match.'
                                    : null,
                              ),
                            ),
                        ] else ...[
                          _field(_key, 'Personal heritage key'),
                          const AppText(
                            'This key signs in to its ownerâ€™s account. To join a family, use your own account and their invitation.',
                          ),
                          const SizedBox(height: 18),
                        ],
                        KkevoButton(
                          label: _register ? 'Create my account' : 'Sign in',
                          busy: auth.isLoading,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => setState(() {
                                  _register = !_register;
                                  _useKey = false;
                                  _error = null;
                                }),
                          child: AppText(
                            _register
                                ? 'Already have an account? Sign in'
                                : 'New here? Create an account',
                          ),
                        ),
                        if (!_register)
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RecoveryView(),
                                    ),
                                  ),
                            child: const AppText('Forgot your password?'),
                          ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: auth.isLoading
                              ? null
                              : () => ServerSettingsDialog.show(context),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const AppText('Connection settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
