import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Repository>(
      builder: (context, repo, _) {
        if (repo.isSyncing) {
          return const StatusPill(label: 'SYNCING', color: AppColors.info, icon: Icons.sync);
        }
        if (!repo.isOnline) {
          final suffix = repo.pendingCount > 0 ? ' · ${repo.pendingCount} PENDING' : '';
          return StatusPill(label: 'OFFLINE$suffix', color: AppColors.warning, icon: Icons.cloud_off);
        }
        if (repo.pendingCount > 0) {
          return StatusPill(label: '${repo.pendingCount} PENDING SYNC', color: AppColors.warning, icon: Icons.sync_problem);
        }
        return const StatusPill(label: 'ONLINE', color: AppColors.success, icon: Icons.cloud_done);
      },
    );
  }
}
