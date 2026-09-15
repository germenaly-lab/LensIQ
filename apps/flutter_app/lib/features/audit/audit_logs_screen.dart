import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_locale_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({Key? key}) : super(key: key);

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _search = '';
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final adminProv = context.watch<AdminProvider>();
    final logs = adminProv.auditLogs.where((log) {
      if (_categoryFilter != null && log.category != _categoryFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return log.action.toLowerCase().contains(q) ||
            log.actorName.toLowerCase().contains(q) ||
            log.details.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/audit-logs',
      title: 'Audit Logs',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
                boxShadow: colors.cardShadow,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: colors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: context.tr('Search logs...'),
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _search = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: _categoryFilter,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.surfaceElevated,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                    hint: Text(context.tr('Filter by Status'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.tr('All Statuses'))),
                      const DropdownMenuItem(value: 'camera', child: Text('Camera Events')),
                      const DropdownMenuItem(value: 'roi', child: Text('ROI Adjustments')),
                      const DropdownMenuItem(value: 'incident', child: Text('Incident Actions')),
                      const DropdownMenuItem(value: 'rule', child: Text('Rule Updates')),
                      const DropdownMenuItem(value: 'company', child: Text('Company Events')),
                      const DropdownMenuItem(value: 'brand', child: Text('Brand Events')),
                      const DropdownMenuItem(value: 'branch', child: Text('Branch Events')),
                    ],
                    onChanged: (val) => setState(() => _categoryFilter = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logs List
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_edu_outlined, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text(context.tr('No data found'), style: TextStyle(color: colors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                            boxShadow: colors.cardShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CategoryIcon(category: log.category, colors: colors),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log.action,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM d, yyyy • HH:mm:ss').format(log.timestamp),
                                            style: AppTypography.code.copyWith(fontSize: 11, color: colors.textMuted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        log.details,
                                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline, size: 13, color: colors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            log.actorName,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textPrimary),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.computer_outlined, size: 13, color: colors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            log.ipAddress ?? '127.0.0.1',
                                            style: AppTypography.code.copyWith(fontSize: 11, color: colors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _CategoryIcon extends StatelessWidget {
  final String category;
  final AppSemanticColors colors;

  const _CategoryIcon({required this.category, required this.colors});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (category) {
      case 'camera':
        icon = Icons.videocam_outlined;
        color = colors.primary;
        break;
      case 'roi':
        icon = Icons.crop_free;
        color = colors.secondary;
        break;
      case 'incident':
        icon = Icons.warning_amber_rounded;
        color = colors.warning;
        break;
      case 'company':
        icon = Icons.corporate_fare;
        color = colors.primary;
        break;
      case 'brand':
        icon = Icons.storefront;
        color = colors.secondary;
        break;
      case 'branch':
        icon = Icons.store_mall_directory;
        color = colors.info;
        break;
      case 'rule':
      default:
        icon = Icons.tune;
        color = colors.accent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
