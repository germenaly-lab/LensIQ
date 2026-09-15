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

  void _openIncidentDetails(BuildContext context, IncidentModel incident) {
    showDialog(
      context: context,
      builder: (ctx) => _IncidentDetailsModal(incident: incident),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentProv = context.watch<IncidentProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return const Scaffold(body: LoadingView());

    final filteredIncidents = incidentProv.incidents;

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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search and Brand / Branch dropdowns
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                              hintText: 'Search by title, camera, branch, or description...',
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              suffixIcon: incidentProv.searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () => incidentProv.setSearchQuery(''),
                                    )
                                  : null,
                            ),
                            onChanged: (v) => incidentProv.setSearchQuery(v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (user.isSuperAdmin) ...[
                          DropdownButton<String?>(
                            value: incidentProv.filterBrand,
                            underline: const SizedBox.shrink(),
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            hint: const Text('All Brands', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('All Brands')),
                              DropdownMenuItem(value: 'Ego', child: Text('Ego Fashion')),
                              DropdownMenuItem(value: 'Armani', child: Text('Armani Exchange')),
                            ],
                            onChanged: (val) => incidentProv.setFilterBrand(val),
                          ),
                          const SizedBox(width: 12),
                        ] else if (user.isBrandManager) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(user.brandName ?? 'Brand', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (!user.isBranchSecurity)
                          DropdownButton<String?>(
                            value: incidentProv.filterBranch,
                            underline: const SizedBox.shrink(),
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            hint: const Text('All Branches', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            items: user.isBrandManager
                                ? const [
                                    DropdownMenuItem(value: null, child: Text('All Brand Branches')),
                                    DropdownMenuItem(value: 'Mall of Arabia', child: Text('Mall of Arabia')),
                                    DropdownMenuItem(value: 'Cairo Festival', child: Text('Cairo Festival City')),
                                  ]
                                : const [
                                    DropdownMenuItem(value: null, child: Text('All Branches')),
                                    DropdownMenuItem(value: 'Mall of Arabia', child: Text('Mall of Arabia')),
                                    DropdownMenuItem(value: 'Cairo Festival', child: Text('Cairo Festival City')),
                                    DropdownMenuItem(value: 'City Stars', child: Text('City Stars')),
                                  ],
                            onChanged: (val) => incidentProv.setFilterBranch(val),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(user.branchName ?? 'Assigned Branch', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Severity & Status Chips
                    Row(
                      children: [
                        const Text('Severity:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        _ChipButton(
                          label: 'All',
                          isSelected: incidentProv.filterSeverity == null,
                          onTap: () => incidentProv.setFilterSeverity(null),
                        ),
                        const SizedBox(width: 6),
                        _ChipButton(
                          label: 'Critical',
                          isSelected: incidentProv.filterSeverity == IncidentSeverity.critical,
                          color: AppColors.severityCritical,
                          onTap: () => incidentProv.setFilterSeverity(IncidentSeverity.critical),
                        ),
                        const SizedBox(width: 6),
                        _ChipButton(
                          label: 'Warning',
                          isSelected: incidentProv.filterSeverity == IncidentSeverity.warning,
                          color: AppColors.severityWarning,
                          onTap: () => incidentProv.setFilterSeverity(IncidentSeverity.warning),
                        ),
                        const SizedBox(width: 6),
                        _ChipButton(
                          label: 'Info',
                          isSelected: incidentProv.filterSeverity == IncidentSeverity.info,
                          color: AppColors.severityInfo,
                          onTap: () => incidentProv.setFilterSeverity(IncidentSeverity.info),
                        ),
                        const SizedBox(width: 20),
                        const Text('Status:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        _ChipButton(
                          label: 'All',
                          isSelected: incidentProv.filterStatus == null,
                          onTap: () => incidentProv.setFilterStatus(null),
                        ),
                        const SizedBox(width: 6),
                        _ChipButton(
                          label: 'Open',
                          isSelected: incidentProv.filterStatus == IncidentStatus.open,
                          color: AppColors.error,
                          onTap: () => incidentProv.setFilterStatus(IncidentStatus.open),
                        ),
                        const SizedBox(width: 6),
                        _ChipButton(
                          label: 'Acknowledged',
                          isSelected: incidentProv.filterStatus == IncidentStatus.acknowledged,
                          color: AppColors.warning,
                          onTap: () => incidentProv.setFilterStatus(IncidentStatus.acknowledged),
                        ),
                        const SizedBox(width: 6),
                        _ChipButton(
                          label: 'Resolved',
                          isSelected: incidentProv.filterStatus == IncidentStatus.resolved,
                          color: AppColors.success,
                          onTap: () => incidentProv.setFilterStatus(IncidentStatus.resolved),
                        ),
                        const SizedBox(width: 6),
                        _ChipButton(
                          label: 'False Pos',
                          isSelected: incidentProv.filterStatus == IncidentStatus.falsePositive,
                          color: AppColors.textMuted,
                          onTap: () => incidentProv.setFilterStatus(IncidentStatus.falsePositive),
                        ),
                      ],
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
                            return _IncidentCard(
                              incident: inc,
                              onOpen: () => _openIncidentDetails(context, inc),
                              onAcknowledge: () => incidentProv.acknowledgeIncident(inc.id),
                              onResolve: () => incidentProv.resolveIncident(inc.id, 'Verified by operator'),
                              onFalsePositive: () => incidentProv.markFalsePositive(inc.id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? c : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onOpen;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onFalsePositive;

  const _IncidentCard({
    required this.incident,
    required this.onOpen,
    required this.onAcknowledge,
    required this.onResolve,
    required this.onFalsePositive,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MMM dd, yyyy • HH:mm:ss').format(incident.timestamp);

    Color statusBadgeColor;
    switch (incident.status) {
      case IncidentStatus.open:
        statusBadgeColor = AppColors.error;
        break;
      case IncidentStatus.acknowledged:
        statusBadgeColor = AppColors.warning;
        break;
      case IncidentStatus.resolved:
        statusBadgeColor = AppColors.success;
        break;
      case IncidentStatus.falsePositive:
        statusBadgeColor = AppColors.textMuted;
        break;
    }

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBadgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    incident.status.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusBadgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(timeStr, style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: 10),
            Text(incident.description, style: AppTypography.body),
            const SizedBox(height: 14),
            Row(
              children: [
                // Brand & Branch Location
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
                      const Icon(Icons.store, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${incident.brandName ?? "Ego Fashion"} • ${incident.branchName}',
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                      Text(incident.cameraName, style: AppTypography.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                if (incident.durationSeconds != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Elapsed: ${incident.durationSeconds}s',
                      style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),

                // Action Buttons for Super Admin
                OutlinedButton(
                  onPressed: onOpen,
                  child: const Text('Open Details'),
                ),
                if (incident.status == IncidentStatus.open) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAcknowledge,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                    child: const Text('Acknowledge'),
                  ),
                ],
                if (incident.status == IncidentStatus.acknowledged || incident.status == IncidentStatus.open) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onResolve,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Resolve'),
                  ),
                ],
                if (incident.status != IncidentStatus.falsePositive) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.textMuted),
                    tooltip: 'Mark False Positive',
                    onPressed: onFalsePositive,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentDetailsModal extends StatelessWidget {
  final IncidentModel incident;

  const _IncidentDetailsModal({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SeverityBadge(severity: incident.severity),
                    const SizedBox(width: 12),
                    Text(incident.title, style: AppTypography.h2),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Camera Snapshot / HUD Placeholder
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam, size: 48, color: Colors.white24),
                        const SizedBox(height: 8),
                        Text(
                          'EVENT SNAPSHOT: ${incident.cameraName.toUpperCase()}',
                          style: AppTypography.code.copyWith(fontSize: 12, color: Colors.white70),
                        ),
                        Text(
                          'Confidence Score: ${((incident.confidence ?? 0.94) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'RULE: ${incident.ruleType.toUpperCase()}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(incident.description, style: AppTypography.body),
            const SizedBox(height: 16),

            _DetailRow(label: 'Retail Brand', value: incident.brandName ?? 'Ego Fashion'),
            _DetailRow(label: 'Assigned Branch', value: incident.branchName),
            _DetailRow(label: 'Source Camera', value: incident.cameraName),
            _DetailRow(label: 'Elapsed Duration', value: '${incident.durationSeconds ?? 0} seconds'),
            _DetailRow(
              label: 'Detection Timestamp',
              value: DateFormat('yyyy-MM-dd HH:mm:ss').format(incident.timestamp),
            ),
            if (incident.resolutionNote != null)
              _DetailRow(label: 'Resolution Note', value: incident.resolutionNote!),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
