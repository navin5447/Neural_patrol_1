import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_session.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officerIdController = TextEditingController(text: 'DEMO-001');
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _officerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(Future<LoginOutcome> Function() action) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final outcome = await action();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!outcome.success) {
      setState(() => _error = outcome.error ?? 'Login failed.');
    }
    // On success, AppSession.notifyListeners() (already called inside the
    // login/demoLogin action) makes AuthGate swap to the dashboard.
  }

  void _secureLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _submit(() => context.read<AppSession>().login(
          officerId: _officerIdController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.3,
                  colors: [AppColors.surfaceHighlight.withValues(alpha: 0.55), AppColors.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.14),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.accent, size: 32),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'NEURAL PATROL',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 2.6),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SPECIESTRACE · PRESUMPTIVE FIELD SCREENING',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.6),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _officerIdController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(labelText: 'Officer ID', prefixIcon: Icon(Icons.badge_outlined)),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Officer ID is required' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _secureLogin(),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline, size: 15, color: AppColors.danger),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: _submitting ? null : _secureLogin,
                                child: _submitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentOn),
                                      )
                                    : const Text('SECURE LOGIN'),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.bolt, size: 17),
                                label: const Text('DEMO LOGIN'),
                                onPressed: _submitting ? null : () => _submit(() => session.demoLogin()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        icon: const Icon(Icons.dns_outlined, size: 15, color: AppColors.textMuted),
                        label: Text(
                          session.apiBaseUrl.isEmpty ? 'Configure server' : session.apiBaseUrl,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                        ),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
