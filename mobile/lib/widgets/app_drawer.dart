import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../screens/settings_screen.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import 'confirm_dialog.dart';
import 'sync_status_badge.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final user = session.currentUser;
    final initials = (user?.name ?? '?').trim().isEmpty
        ? '?'
        : user!.name.trim().split(RegExp(r'\s+')).map((s) => s[0]).take(2).join().toUpperCase();

    return Drawer(
      backgroundColor: AppColors.surface,
      width: 300,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surfaceHighlight, AppColors.surface],
                ),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: Text(initials, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Unknown Officer', style: AppText.h3, overflow: TextOverflow.ellipsis),
                            Text('${user?.officerId ?? ''} · ${(user?.role ?? '').replaceAll('_', ' ').toUpperCase()}',
                                style: AppText.caption, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SyncStatusBadge(),
                  if (session.offlineLogin) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.warning),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Local demo identity — not yet verified by the server. Reconnects automatically once online.',
                            style: TextStyle(color: AppColors.warning, fontSize: 11, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
            Consumer<Repository>(
              builder: (context, repo, _) => _DrawerItem(
                icon: Icons.sync,
                label: 'Sync now',
                subtitle: repo.pendingCount > 0 ? '${repo.pendingCount} record(s) waiting' : 'Up to date',
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<AppSession>().reconnect();
                },
              ),
            ),
            _DrawerItem(
              icon: Icons.dns_outlined,
              label: 'Backend connection',
              subtitle: session.apiBaseUrl,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Log out',
              iconColor: AppColors.danger,
              labelColor: AppColors.danger,
              onTap: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Log out?',
                  message: 'Any data waiting to sync stays queued locally and will upload next time you sign back in with connectivity.',
                  confirmLabel: 'LOG OUT',
                  danger: true,
                );
                if (!confirmed || !context.mounted) return;
                final navigator = Navigator.of(context);
                await context.read<AppSession>().logout();
                navigator.popUntil((r) => r.isFirst);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
      title: Text(label, style: TextStyle(color: labelColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle!, style: AppText.caption, overflow: TextOverflow.ellipsis) : null,
      onTap: onTap,
    );
  }
}
