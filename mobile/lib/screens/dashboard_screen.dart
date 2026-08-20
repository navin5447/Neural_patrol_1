import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/case_file.dart';
import '../models/dashboard_summary.dart';
import '../models/sample.dart';
import '../state/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/new_case_dialog.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_pill.dart';
import '../widgets/sync_status_badge.dart';
import 'create_sample_screen.dart';
import 'evidence_record_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Repository _repo;
  late Future<DashboardSummary> _summaryFuture;
  late Future<List<CaseFile>> _casesFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = context.read<Repository>();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    _summaryFuture = _repo.getDashboardSummary();
    _casesFuture = _repo.listCases();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_summaryFuture, _casesFuture]);
  }

  Future<void> _startNewSample() async {
    final cases = await _casesFuture.catchError((_) => <CaseFile>[]);
    if (!mounted) return;
    final chosen = await showModalBottomSheet<CaseFile>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CasePickerSheet(cases: cases),
    );
    if (chosen == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateSampleScreen(caseFile: chosen)));
    if (mounted) await _refresh();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final officerName = context.watch<AppSession>().currentUser?.name.split(' ').first ?? 'Officer';
    return Scaffold(
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              expandedHeight: 108,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                title: Text('${_greeting()}, $officerName', style: AppText.h3, overflow: TextOverflow.ellipsis),
                background: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.surfaceHighlight, AppColors.background],
                    ),
                  ),
                ),
              ),
              actions: const [Padding(padding: EdgeInsets.only(right: 14, top: 4), child: SyncStatusBadge())],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FutureBuilder<DashboardSummary>(
                    future: _summaryFuture,
                    builder: (context, snapshot) {
                      final summary = snapshot.data ?? const DashboardSummary();
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.5,
                        children: [
                          StatTile(label: 'Active Cases', value: '${summary.activeCases}', icon: Icons.folder_open, accent: AppColors.accent),
                          StatTile(label: "Today's Samples", value: '${summary.todaysSamples}', icon: Icons.science_outlined, accent: AppColors.teal),
                          StatTile(label: 'Pending FSL', value: '${summary.pendingFsl}', icon: Icons.local_shipping_outlined, accent: AppColors.warning),
                          StatTile(label: 'Field Results', value: '${summary.fieldResultsCount}', icon: Icons.fact_check_outlined, accent: AppColors.info),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'Cases & samples',
                    trailing: TextButton.icon(
                      onPressed: _startNewSample,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('NEW SAMPLE'),
                    ),
                  ),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by case number, title, or location…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FutureBuilder<List<CaseFile>>(
                    future: _casesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError) {
                        return ErrorState(message: 'Could not load cases.', onRetry: () => setState(_load));
                      }
                      final cases = snapshot.data ?? [];
                      final filtered = _query.isEmpty
                          ? cases
                          : cases
                              .where((c) =>
                                  c.caseNumber.toLowerCase().contains(_query) ||
                                  (c.title ?? '').toLowerCase().contains(_query) ||
                                  (c.location ?? '').toLowerCase().contains(_query))
                              .toList();
                      if (cases.isEmpty) {
                        return EmptyState(
                          icon: Icons.folder_off_outlined,
                          title: 'No cases yet',
                          message: 'Register the first case and sample to start a chain of custody.',
                          actionLabel: 'NEW SAMPLE',
                          onAction: _startNewSample,
                        );
                      }
                      if (filtered.isEmpty) {
                        return EmptyState(icon: Icons.search_off, title: 'No matches', message: 'No case matches "$_query".');
                      }
                      return Column(
                        children: filtered.map((c) => _CaseExpansionTile(caseFile: c, onSampleReturned: _refresh)).toList(),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseExpansionTile extends StatefulWidget {
  final CaseFile caseFile;
  final Future<void> Function() onSampleReturned;

  const _CaseExpansionTile({required this.caseFile, required this.onSampleReturned});

  @override
  State<_CaseExpansionTile> createState() => _CaseExpansionTileState();
}

class _CaseExpansionTileState extends State<_CaseExpansionTile> {
  Future<List<Sample>>? _samplesFuture;

  @override
  Widget build(BuildContext context) {
    final c = widget.caseFile;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded && _samplesFuture == null) {
              setState(() => _samplesFuture = context.read<Repository>().listSamples(caseId: c.id));
            }
          },
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.folder_outlined, size: 17, color: AppColors.accent),
          ),
          title: Text(c.caseNumber, style: AppText.bodyStrong),
          subtitle: Text(c.title ?? c.location ?? 'No description', style: AppText.caption, overflow: TextOverflow.ellipsis),
          trailing: c.pendingSync
              ? const StatusPill(label: 'PENDING', color: AppColors.warning)
              : const Icon(Icons.expand_more, color: AppColors.textMuted),
          children: [
            FutureBuilder<List<Sample>>(
              future: _samplesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text('Could not load samples for this case.', style: TextStyle(color: AppColors.danger, fontSize: 12.5)),
                  );
                }
                final samples = snapshot.data ?? [];
                if (samples.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No samples registered for this case yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    ),
                  );
                }
                return Column(
                  children: samples
                      .map((s) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.qr_code_2, color: AppColors.accent, size: 20),
                            title: Text(s.sampleCode, style: AppText.mono.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            subtitle: Text(s.sampleType, style: AppText.caption),
                            trailing: s.pendingSync ? const StatusPill(label: 'PENDING', color: AppColors.warning) : const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => EvidenceRecordScreen(sample: s, caseFile: c),
                              ));
                              await widget.onSampleReturned();
                            },
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _CasePickerSheet extends StatelessWidget {
  final List<CaseFile> cases;

  const _CasePickerSheet({required this.cases});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            Text('Register sample under', style: AppText.h3),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('NEW CASE / FIR'),
              onPressed: () async {
                final created = await showNewCaseDialog(context);
                if (created != null && context.mounted) Navigator.of(context).pop(created);
              },
            ),
            if (cases.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Existing cases', padding: EdgeInsets.only(bottom: 6)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cases.length,
                  itemBuilder: (context, i) {
                    final c = cases[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_open, color: AppColors.accent),
                      title: Text(c.caseNumber, style: AppText.bodyStrong),
                      subtitle: Text(c.title ?? c.location ?? '', style: AppText.caption),
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
