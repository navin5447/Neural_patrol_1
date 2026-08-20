import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'state/app_session.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const NeuralPatrolApp());
}

/// Owns the single [AppSession] (and, transitively, the single [Repository])
/// for the app's lifetime. Both are provided ABOVE [MaterialApp] — and so
/// above its [Navigator] — because provider scoping follows the widget
/// tree, not route-push order: anything provided only inside a particular
/// route's subtree (e.g. inside [AuthGate]'s builder) is invisible to
/// sibling routes reached via Navigator.push, since pushed routes render
/// into sibling Overlay entries rather than descending from the route that
/// pushed them.
class NeuralPatrolApp extends StatefulWidget {
  const NeuralPatrolApp({super.key});

  @override
  State<NeuralPatrolApp> createState() => _NeuralPatrolAppState();
}

class _NeuralPatrolAppState extends State<NeuralPatrolApp> {
  final _session = AppSession();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSession>.value(value: _session),
        ChangeNotifierProvider<Repository>.value(value: _session.repository),
      ],
      child: MaterialApp(
        title: 'SpeciesTrace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}

/// Restores a previous session on launch and routes to the login flow or
/// straight into the dashboard.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = context.read<AppSession>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashView();
        }
        final session = context.watch<AppSession>();
        return session.isAuthenticated ? const DashboardScreen() : const LoginScreen();
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1.4),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 22),
            const Text(
              'NEURAL PATROL',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'SPECIESTRACE FIELD UNIT',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 3),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
