import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/incident.dart';

class DashboardCharts extends StatelessWidget {
  final Map<String, int> incidentsByBrand;
  final Map<String, int> incidentsByBranch;
  final Map<String, int> incidentsOverTime;
  final Map<IncidentSeverity, int> incidentsBySeverity;
  final double cameraAvailability;
  final int totalCameras;
  final int onlineCameras;

  const DashboardCharts({
    Key? key,
    required this.incidentsByBrand,
    required this.incidentsByBranch,
    required this.incidentsOverTime,
    required this.incidentsBySeverity,
    required this.cameraAvailability,
    required this.totalCameras,
    required this.onlineCameras,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Row 1: Brand Distribution & Camera Availability
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Incidents By Brand
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Incidents by Retail Brand', style: AppTypography.h3),
                          Text('Database Seed Data', style: AppTypography.caption),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (incidentsByBrand.isEmpty)
                        const Text('No incident data found.', style: AppTypography.caption)
                      else
                        ...incidentsByBrand.entries.map((entry) {
                          final total = incidentsByBrand.values.fold(0, (a, b) => a + b);
                          final pct = total > 0 ? (entry.value / total) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: AppTypography.bodyMedium),
                                    Text(
                                      '${entry.value} incidents (${(pct * 100).toStringAsFixed(0)}%)',
                                      style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 8,
                                    backgroundColor: AppColors.background,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      entry.key.contains('Armani')
                                          ? AppColors.secondary
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. Camera Availability & Health Gauge
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Camera Fleet Availability', style: AppTypography.h3),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    value: cameraAvailability / 100.0,
                                    strokeWidth: 10,
                                    backgroundColor: AppColors.background,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${cameraAvailability.toStringAsFixed(1)}%',
                                      style: AppTypography.h2.copyWith(color: AppColors.success),
                                    ),
                                    const Text('Online', style: AppTypography.caption),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$onlineCameras of $totalCameras cameras streaming live',
                              style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Charts Row 2: Branch Comparison & Severity Distribution & Over Time
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. Incidents by Branch
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Incidents by Branch', style: AppTypography.h3),
                      const SizedBox(height: 16),
                      ...incidentsByBranch.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.key,
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (entry.value / 5.0).clamp(0.1, 1.0),
                                    minHeight: 8,
                                    backgroundColor: AppColors.background,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${entry.value}', style: AppTypography.code.copyWith(fontSize: 12)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 4. Incident Severity Distribution
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Incident Severity', style: AppTypography.h3),
                      const SizedBox(height: 16),
                      _buildSeverityBar(
                        label: 'Critical Alerts',
                        count: incidentsBySeverity[IncidentSeverity.critical] ?? 0,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 10),
                      _buildSeverityBar(
                        label: 'Warning Events',
                        count: incidentsBySeverity[IncidentSeverity.warning] ?? 0,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 10),
                      _buildSeverityBar(
                        label: 'Info Logs',
                        count: incidentsBySeverity[IncidentSeverity.info] ?? 0,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 5. Timeline / Over Time
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Incidents Over Time (Today)', style: AppTypography.h3),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: incidentsOverTime.entries.map((entry) {
                          final h = (entry.value * 9.0).clamp(10.0, 70.0);
                          return Column(
                            children: [
                              Text('${entry.value}', style: AppTypography.caption.copyWith(fontSize: 10)),
                              const SizedBox(height: 4),
                              Container(
                                width: 14,
                                height: h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(entry.key, style: AppTypography.caption.copyWith(fontSize: 9)),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityBar({required String label, required int count, required Color color}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTypography.bodySecondary.copyWith(fontSize: 12)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}
