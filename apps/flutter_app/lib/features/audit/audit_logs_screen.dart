import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
      title: 'Security & Audit Logs',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                          hintText: 'Search audit events by action or actor...',
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() => _search = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String?>(
                      value: _categoryFilter,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      hint: const Text('All Categories', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Categories')),
                        DropdownMenuItem(value: 'camera', child: Text('Camera Events')),
                        DropdownMenuItem(value: 'roi', child: Text('ROI Adjustments')),
                        DropdownMenuItem(value: 'incident', child: Text('Incident Actions')),
                        DropdownMenuItem(value: 'rule', child: Text('Rule Updates')),
                      ],
                      onChanged: (val) => setState(() => _categoryFilter = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logs List
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('No audit events found.'))
                  : ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CategoryIcon(category: log.category),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(log.action, style: AppTypography.h3),
                                          Text(
                                            DateFormat('MMM dd, yyyy • HH:mm:ss').format(log.timestamp),
                                            style: AppTypography.code.copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Actor: ${log.actorName} • Role: ${log.actorRole}${log.ipAddress != null ? " • IP: ${log.ipAddress}" : ""}',
                                        style: AppTypography.caption,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(log.details, style: AppTypography.bodySecondary.copyWith(fontSize: 12)),
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

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (category) {
      case 'camera':
        icon = Icons.videocam_outlined;
        color = AppColors.primary;
        break;
      case 'roi':
        icon = Icons.crop;
        color = AppColors.secondary;
        break;
      case 'incident':
        icon = Icons.warning_amber_rounded;
        color = AppColors.warning;
        break;
      case 'rule':
        icon = Icons.tune;
        color = AppColors.accent;
        break;
      default:
        icon = Icons.security;
        color = AppColors.textMuted;
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
