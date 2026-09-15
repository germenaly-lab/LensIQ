import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_locale_provider.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/admin_provider.dart';
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
        context.read<AdminProvider>().loadAllAdminData(user);
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
    final adminProv = context.watch<AdminProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final colors = context.colors;

    if (user == null) return const Scaffold(body: LoadingView());

    final filteredIncidents = incidentProv.incidents;

    return ResponsiveScaffold(
      currentRoute: '/incidents',
      title: 'Incidents',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: context.tr('Refresh Realtime Data'),
          onPressed: () => incidentProv.loadData(user),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
                boxShadow: colors.cardShadow,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search and Brand / Branch dropdowns
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          style: TextStyle(fontSize: 14, color: colors.textPrimary),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, size: 18, color: colors.textMuted),
                            hintText: context.tr('Search incidents...'),
                            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                            isDense: true,
                            suffixIcon: incidentProv.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 16, color: colors.textMuted),
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
                          dropdownColor: colors.surfaceElevated,
                          style: TextStyle(fontSize: 12, color: colors.textPrimary),
                          hint: Text(context.tr('All Brands'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                          items: [
                            DropdownMenuItem(value: null, child: Text(context.tr('All Brands'))),
                            ...adminProv.brands.map(
                              (b) => DropdownMenuItem(value: b.name, child: Text(b.name)),
                            ),
                          ],
                          onChanged: (val) => incidentProv.setFilterBrand(val),
                        ),
                        const SizedBox(width: 12),
                      ] else if (user.isBrandManager) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.brandName ?? 'Brand',
                            style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (!user.isBranchSecurity)
                        DropdownButton<String?>(
                          value: incidentProv.filterBranch,
                          underline: const SizedBox.shrink(),
                          dropdownColor: colors.surfaceElevated,
                          style: TextStyle(fontSize: 12, color: colors.textPrimary),
                          hint: Text(context.tr('All Branches'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                          items: [
                            DropdownMenuItem(value: null, child: Text(context.tr('All Branches'))),
                            ...adminProv.branches.map(
                              (br) => DropdownMenuItem(value: br.name, child: Text(br.name)),
                            ),
                          ],
                          onChanged: (val) => incidentProv.setFilterBranch(val),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.branchName ?? 'Assigned Branch',
                            style: TextStyle(color: colors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  Divider(height: 20, color: colors.borderSubtle),

                  // Severity & Status Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${context.tr("Filter by Severity")}:', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                      _ChipButton(
                        label: context.tr('All Severities'),
                        isSelected: incidentProv.filterSeverity == null,
                        colors: colors,
                        onTap: () => incidentProv.setFilterSeverity(null),
                      ),
                      _ChipButton(
                        label: context.tr('Critical'),
                        isSelected: incidentProv.filterSeverity == IncidentSeverity.critical,
                        color: colors.severityCritical,
                        colors: colors,
                        onTap: () => incidentProv.setFilterSeverity(IncidentSeverity.critical),
                      ),
                      _ChipButton(
                        label: context.tr('Warning'),
                        isSelected: incidentProv.filterSeverity == IncidentSeverity.warning,
                        color: colors.severityWarning,
                        colors: colors,
                        onTap: () => incidentProv.setFilterSeverity(IncidentSeverity.warning),
                      ),
                      _ChipButton(
                        label: context.tr('Info'),
                        isSelected: incidentProv.filterSeverity == IncidentSeverity.info,
                        color: colors.severityInfo,
                        colors: colors,
                        onTap: () => incidentProv.setFilterSeverity(IncidentSeverity.info),
                      ),
                      const SizedBox(width: 14),
                      Text('${context.tr("Filter by Status")}:', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                      _ChipButton(
                        label: context.tr('All Statuses'),
                        isSelected: incidentProv.filterStatus == null,
                        colors: colors,
                        onTap: () => incidentProv.setFilterStatus(null),
                      ),
                      _ChipButton(
                        label: context.tr('Open'),
                        isSelected: incidentProv.filterStatus == IncidentStatus.open,
                        color: colors.error,
                        colors: colors,
                        onTap: () => incidentProv.setFilterStatus(IncidentStatus.open),
                      ),
                      _ChipButton(
                        label: context.tr('Acknowledged'),
                        isSelected: incidentProv.filterStatus == IncidentStatus.acknowledged,
                        color: colors.warning,
                        colors: colors,
                        onTap: () => incidentProv.setFilterStatus(IncidentStatus.acknowledged),
                      ),
                      _ChipButton(
                        label: context.tr('Resolved'),
                        isSelected: incidentProv.filterStatus == IncidentStatus.resolved,
                        color: colors.success,
                        colors: colors,
                        onTap: () => incidentProv.setFilterStatus(IncidentStatus.resolved),
                      ),
                      _ChipButton(
                        label: context.tr('False Positive'),
                        isSelected: incidentProv.filterStatus == IncidentStatus.falsePositive,
                        color: colors.textMuted,
                        colors: colors,
                        onTap: () => incidentProv.setFilterStatus(IncidentStatus.falsePositive),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Incident List
            Expanded(
              child: incidentProv.isLoading
                  ? LoadingView(message: context.tr('Loading...'))
                  : filteredIncidents.isEmpty
                      ? EmptyStateView(
                          icon: Icons.notifications_off_outlined,
                          title: context.tr('No incidents found'),
                          description: context.tr('No incidents found'),
                        )
                      : ListView.separated(
                          itemCount: filteredIncidents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final inc = filteredIncidents[index];
                            return _IncidentCard(
                              incident: inc,
                              colors: colors,
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
  final AppSemanticColors colors;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.isSelected,
    this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.15) : colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? c : colors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? c : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final AppSemanticColors colors;
  final VoidCallback onOpen;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;
  final VoidCallback onFalsePositive;

  const _IncidentCard({
    required this.incident,
    required this.colors,
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
        statusBadgeColor = colors.error;
        break;
      case IncidentStatus.acknowledged:
        statusBadgeColor = colors.warning;
        break;
      case IncidentStatus.resolved:
        statusBadgeColor = colors.success;
        break;
      case IncidentStatus.falsePositive:
        statusBadgeColor = colors.textMuted;
        break;
    }

    final accentBorder = incident.isCritical ? colors.error : (incident.isWarning ? colors.warning : colors.info);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: BorderDirectional(
          start: BorderSide(color: accentBorder, width: 4),
          top: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
          end: BorderSide(color: colors.border),
        ),
        boxShadow: colors.cardShadow,
      ),
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
                  context.tr(incident.title),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  context.tr(incident.status.displayName).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusBadgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(timeStr, style: TextStyle(fontSize: 11, color: colors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(incident.description, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Metadata chips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store, size: 14, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${incident.brandName ?? "Ego Fashion"} • ${incident.branchName}',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_outlined, size: 14, color: colors.textMuted),
                        const SizedBox(width: 6),
                        Text(incident.cameraName, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                      ],
                    ),
                  ),
                  if (incident.durationSeconds != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${incident.durationSeconds}s',
                        style: TextStyle(fontSize: 11, color: colors.warning, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: onOpen,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: BorderSide(color: colors.border),
                    ),
                    child: Text(context.tr('Incident Details'), style: TextStyle(fontSize: 12, color: colors.textPrimary)),
                  ),
                  if (incident.status == IncidentStatus.open) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onAcknowledge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(context.tr('Acknowledge'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                  if (incident.status == IncidentStatus.acknowledged || incident.status == IncidentStatus.open) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onResolve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(context.tr('Resolve'), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                  if (incident.status != IncidentStatus.falsePositive) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(Icons.flag_outlined, size: 18, color: colors.textMuted),
                      tooltip: context.tr('Mark as False Positive'),
                      onPressed: onFalsePositive,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncidentDetailsModal extends StatelessWidget {
  final IncidentModel incident;

  const _IncidentDetailsModal({required this.incident});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
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
                    Text(
                      context.tr(incident.title),
                      style: AppTypography.h2Of(context).copyWith(fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: colors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(height: 24, color: colors.borderSubtle),

            // Camera Snapshot / HUD Viewport
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
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
                          '${incident.cameraName} • SNAPSHOT RECORDING',
                          style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.tr(incident.severity.displayName).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              incident.description,
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
            ),
            const SizedBox(height: 14),

            // Details Grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                children: [
                  _ModalRow(label: context.tr('Branch'), value: incident.branchName, colors: colors),
                  _ModalRow(label: context.tr('Camera'), value: incident.cameraName, colors: colors),
                  _ModalRow(
                    label: context.tr('Timestamp'),
                    value: DateFormat('yyyy-MM-dd HH:mm:ss').format(incident.timestamp),
                    colors: colors,
                  ),
                  _ModalRow(label: context.tr('Status'), value: context.tr(incident.status.displayName), colors: colors),
                  if (incident.durationSeconds != null)
                    _ModalRow(
                      label: context.tr('Cooldown (Seconds)'),
                      value: '${incident.durationSeconds}s',
                      colors: colors,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('Close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalRow extends StatelessWidget {
  final String label;
  final String value;
  final AppSemanticColors colors;

  const _ModalRow({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        ],
      ),
    );
  }
}
