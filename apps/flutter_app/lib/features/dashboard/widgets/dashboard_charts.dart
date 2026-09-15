import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/localization/app_locale_provider.dart';
import '../../../core/utils/responsive_util.dart';
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
    final colors = context.colors;
    final isDesktop = ResponsiveUtil.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Charts Row 1: Brand Distribution & Camera Availability
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildBrandDistributionCard(context, colors)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildAvailabilityCard(context, colors)),
            ],
          )
        else ...[
          _buildBrandDistributionCard(context, colors),
          const SizedBox(height: 16),
          _buildAvailabilityCard(context, colors),
        ],
        const SizedBox(height: 16),

        // Charts Row 2: Branch Comparison & Severity Distribution & Over Time
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildBranchComparisonCard(context, colors)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildSeverityDistributionCard(context, colors)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildTimelineCard(context, colors)),
            ],
          )
        else ...[
          _buildBranchComparisonCard(context, colors),
          const SizedBox(height: 16),
          _buildSeverityDistributionCard(context, colors),
          const SizedBox(height: 16),
          _buildTimelineCard(context, colors),
        ],
      ],
    );
  }

  Widget _buildBrandDistributionCard(BuildContext context, AppSemanticColors colors) {
    final total = incidentsByBrand.values.fold(0, (a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('Incidents by Retail Brand'),
                style: AppTypography.h3Of(context).copyWith(fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.tr('Real-time'),
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (incidentsByBrand.isEmpty)
            Text(context.tr('No data found'), style: AppTypography.captionOf(context))
          else
            ...incidentsByBrand.entries.map((entry) {
              final pct = total > 0 ? (entry.value / total) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: AppTypography.bodyOf(context).copyWith(fontSize: 13)),
                        Text(
                          '${entry.value} ${context.tr("Incidents")} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: AppTypography.captionOf(context).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: colors.surfaceSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.key.contains('Armani') ? colors.secondary : colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(BuildContext context, AppSemanticColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Camera Fleet Availability'),
            style: AppTypography.h3Of(context).copyWith(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 95,
                      height: 95,
                      child: CircularProgressIndicator(
                        value: cameraAvailability / 100.0,
                        strokeWidth: 9,
                        backgroundColor: colors.surfaceSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.success),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cameraAvailability.toStringAsFixed(1)}%',
                          style: AppTypography.h2Of(context).copyWith(
                            color: colors.success,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          context.tr('Online'),
                          style: AppTypography.captionOf(context).copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$onlineCameras ${context.tr("of")} $totalCameras ${context.tr("cameras streaming live")}',
                  style: AppTypography.captionOf(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchComparisonCard(BuildContext context, AppSemanticColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Incidents by Branch'),
            style: AppTypography.h3Of(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 14),
          ...incidentsByBranch.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      entry.key,
                      style: AppTypography.bodyOf(context).copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (entry.value / 5.0).clamp(0.1, 1.0),
                        minHeight: 6,
                        backgroundColor: colors.surfaceSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeverityDistributionCard(BuildContext context, AppSemanticColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Incident Severity'),
            style: AppTypography.h3Of(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 14),
          _buildSeverityBar(
            label: context.tr('Critical Alerts'),
            count: incidentsBySeverity[IncidentSeverity.critical] ?? 0,
            color: colors.error,
            colors: colors,
          ),
          const SizedBox(height: 10),
          _buildSeverityBar(
            label: context.tr('Warning Alerts'),
            count: incidentsBySeverity[IncidentSeverity.warning] ?? 0,
            color: colors.warning,
            colors: colors,
          ),
          const SizedBox(height: 10),
          _buildSeverityBar(
            label: context.tr('Info Alerts'),
            count: incidentsBySeverity[IncidentSeverity.info] ?? 0,
            color: colors.secondary,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, AppSemanticColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Incident Trend (Last 7 Days)'),
            style: AppTypography.h3Of(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: incidentsOverTime.entries.map((entry) {
              final h = (entry.value * 9.0).clamp(12.0, 60.0);
              return Column(
                children: [
                  Text(
                    '${entry.value}',
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 14,
                    height: h,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBar({
    required String label,
    required int count,
    required Color color,
    required AppSemanticColors colors,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
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
