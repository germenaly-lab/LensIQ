import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_view.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({Key? key}) : super(key: key);

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  IncidentSeverity? _filterSeverity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<IncidentProvider>().loadData(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final incidentProv = context.watch<IncidentProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return const Scaffold(body: LoadingView());

    final filteredIncidents = incidentProv.incidents.where((i) {
      if (_filterSeverity == null) return true;
      return i.severity == _filterSeverity;
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/incidents',
      title: 'AI Vision Incidents & Alarms',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Incidents',
          onPressed: () => incidentProv.loadData(user),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Text('Severity Filter:', style: AppTypography.bodyMedium),
                    const SizedBox(width: 14),
                    _SeverityFilterChip(
                      label: 'All (${incidentProv.incidents.length})',
                      isSelected: _filterSeverity == null,
                      onTap: () => setState(() => _filterSeverity = null),
                    ),
                    const SizedBox(width: 8),
                    _SeverityFilterChip(
                      label: 'Critical',
                      isSelected: _filterSeverity == IncidentSeverity.critical,
                      onTap: () => setState(() => _filterSeverity = IncidentSeverity.critical),
                      color: AppColors.severityCritical,
                    ),
                    const SizedBox(width: 8),
                    _SeverityFilterChip(
                      label: 'Warning',
                      isSelected: _filterSeverity == IncidentSeverity.warning,
                      onTap: () => setState(() => _filterSeverity = IncidentSeverity.warning),
                      color: AppColors.severityWarning,
                    ),
                    const SizedBox(width: 8),
                    _SeverityFilterChip(
                      label: 'Notice',
                      isSelected: _filterSeverity == IncidentSeverity.info,
                      onTap: () => setState(() => _filterSeverity = IncidentSeverity.info),
                      color: AppColors.severityInfo,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Incident List
            Expanded(
              child: incidentProv.isLoading
                  ? const LoadingView(message: 'Loading AI incident detections...')
                  : filteredIncidents.isEmpty
                      ? const EmptyStateView(
                          icon: Icons.notifications_off_outlined,
                          title: 'No Incidents Found',
                          description: 'No AI security incidents match your selected filters.',
                        )
                      : ListView.separated(
                          itemCount: filteredIncidents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final inc = filteredIncidents[index];
                            return _IncidentCard(incident: inc);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _SeverityFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(incident.timestamp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SeverityBadge(severity: incident.severity),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    incident.title,
                    style: AppTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeStr,
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(incident.description, style: AppTypography.body),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${incident.cameraName} (${incident.branchName})',
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (incident.durationSeconds != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Duration: ${incident.durationSeconds}s',
                      style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    incident.status.name.toUpperCase(),
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
