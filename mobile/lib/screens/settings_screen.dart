import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_store.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  bool _testing = false;
  String? _testResult;
  bool? _testOk;

  @override
  void initState() {
    super.initState();
    final session = context.read<AppSession>();
    _urlController = TextEditingController(text: session.apiBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final session = context.read<AppSession>();
    final previousUrl = session.api.baseUrl;
    session.api.baseUrl = _urlController.text.trim();
    final ok = await session.api.ping();
    session.api.baseUrl = previousUrl;
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = ok;
      _testResult = ok ? 'Backend reachable.' : 'Could not reach that address.';
    });
  }

  Future<void> _save() async {
    final session = context.read<AppSession>();
    await session.updateApiBaseUrl(_urlController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server address saved.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend Connection')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SectionCard(
            title: 'API base URL',
            titleIcon: Icons.dns_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Point this at the FastAPI backend for your network. Android emulator defaults to 10.0.2.2 — a physical device, browser, or iOS simulator needs your machine\'s LAN IP.',
                  style: AppText.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'http://<host>:8000', prefixIcon: Icon(Icons.link)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(label: const Text('10.0.2.2:8000'), onPressed: () => setState(() => _urlController.text = 'http://10.0.2.2:8000')),
                    ActionChip(label: const Text('localhost:8000'), onPressed: () => setState(() => _urlController.text = 'http://localhost:8000')),
                    ActionChip(label: Text(SettingsStore.defaultBaseUrl()), onPressed: () => setState(() => _urlController.text = SettingsStore.defaultBaseUrl())),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(_testOk == true ? Icons.check_circle : Icons.error, size: 16, color: _testOk == true ? AppColors.success : AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_testResult!, style: TextStyle(color: _testOk == true ? AppColors.success : AppColors.danger, fontSize: 12.5))),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  child: _testing
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('TEST CONNECTION'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(onPressed: _save, child: const Text('SAVE')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Offline-first design',
            titleIcon: Icons.cloud_off,
            child: const Text(
              'If the backend cannot be reached, case, sample, custody, result, and FSL-handoff records are still created locally and queued for sync. They upload automatically the next time the app reaches the backend.',
              style: AppText.bodyMuted,
            ),
          ),
        ],
      ),
    );
  }
}
