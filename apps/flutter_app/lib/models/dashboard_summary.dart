class DashboardSummary {
  final int totalCameras;
  final int onlineCameras;
  final int offlineCameras;
  final int activeIncidents;
  final int criticalAlerts;
  final int totalBranches;
  final int incidentsToday;
  final int cashierAlerts;
  final double networkUptimePercentage;

  const DashboardSummary({
    required this.totalCameras,
    required this.onlineCameras,
    required this.offlineCameras,
    required this.activeIncidents,
    required this.criticalAlerts,
    required this.totalBranches,
    required this.incidentsToday,
    required this.cashierAlerts,
    this.networkUptimePercentage = 99.8,
  });

  factory DashboardSummary.initial() {
    return const DashboardSummary(
      totalCameras: 0,
      onlineCameras: 0,
      offlineCameras: 0,
      activeIncidents: 0,
      criticalAlerts: 0,
      totalBranches: 0,
      incidentsToday: 0,
      cashierAlerts: 0,
      networkUptimePercentage: 100.0,
    );
  }
}
