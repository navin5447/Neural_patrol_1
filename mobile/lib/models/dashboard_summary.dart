class DashboardSummary {
  final int activeCases;
  final int todaysSamples;
  final int pendingFsl;
  final int fieldResultsCount;

  const DashboardSummary({
    this.activeCases = 0,
    this.todaysSamples = 0,
    this.pendingFsl = 0,
    this.fieldResultsCount = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        activeCases: json['active_cases'] as int? ?? 0,
        todaysSamples: json['todays_samples'] as int? ?? 0,
        pendingFsl: json['pending_fsl'] as int? ?? 0,
        fieldResultsCount: json['field_results_count'] as int? ?? 0,
      );
}
