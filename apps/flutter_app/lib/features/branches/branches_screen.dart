import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../models/branch.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({Key? key}) : super(key: key);

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final isDesktop = ResponsiveUtil.isDesktop(context);

    final filtered = adminProv.branches.where((b) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
          b.code.toLowerCase().contains(q) ||
          b.address.toLowerCase().contains(q);
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/branches',
      title: 'Branch Operations Overview',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    hintText: 'Search branches by name, code, or address...',
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Branches Grid
            Expanded(
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : (ResponsiveUtil.isTablet(context) ? 2 : 1),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (context, index) {
                  final branch = filtered[index];
                  return _BranchCard(branch: branch);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchModel branch;

  const _BranchCard({required this.branch});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (branch.status) {
      case 'operational':
        statusColor = AppColors.success;
        break;
      case 'alert':
        statusColor = AppColors.warning;
        break;
      case 'degraded':
      default:
        statusColor = AppColors.error;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    branch.code,
                    style: AppTypography.code.copyWith(fontSize: 11, color: AppColors.primaryLight),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    branch.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(branch.name, style: AppTypography.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              branch.address,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BranchStat(
                  label: 'Cameras',
                  value: '${branch.onlineCameraCount}/${branch.cameraCount}',
                  color: AppColors.primary,
                ),
                _BranchStat(
                  label: 'Alerts',
                  value: '${branch.activeIncidentCount}',
                  color: branch.activeIncidentCount > 0 ? AppColors.warning : AppColors.success,
                ),
                _BranchStat(
                  label: 'Health',
                  value: branch.isOperational ? '100%' : '75%',
                  color: statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BranchStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
      ],
    );
  }
}
