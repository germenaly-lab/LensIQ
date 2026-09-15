import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../core/localization/app_locale_provider.dart';
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
  String? _selectedBrandFilter;
  String? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final adminProv = context.watch<AdminProvider>();
    final isDesktop = ResponsiveUtil.isDesktop(context);

    final filtered = adminProv.branches.where((b) {
      if (_selectedBrandFilter != null && b.brandId != _selectedBrandFilter) {
        return false;
      }
      if (_selectedStatusFilter != null && b.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
          b.code.toLowerCase().contains(q) ||
          b.address.toLowerCase().contains(q);
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/branches',
      title: 'Branch Management',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddEditBranchDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: Text(context.tr('Add Branch')),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter & Search Bar
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
                        hintText: context.tr('Search branches...'),
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String?>(
                    value: _selectedBrandFilter,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.surfaceElevated,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                    hint: Text(context.tr('All Brands'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.tr('All Brands'))),
                      ...adminProv.brands.map(
                        (br) => DropdownMenuItem(value: br.id, child: Text(br.name)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedBrandFilter = val),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: _selectedStatusFilter,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.surfaceElevated,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                    hint: Text(context.tr('All Statuses'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.tr('All Statuses'))),
                      DropdownMenuItem(value: 'operational', child: Text(context.tr('Healthy'))),
                      DropdownMenuItem(value: 'alert', child: Text(context.tr('Warning'))),
                      DropdownMenuItem(value: 'degraded', child: Text(context.tr('Critical'))),
                    ],
                    onChanged: (val) => setState(() => _selectedStatusFilter = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Branches Grid
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_outlined, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('No data found'),
                            style: AppTypography.bodyOf(context).copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : (ResponsiveUtil.isTablet(context) ? 2 : 1),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.65 : 1.5,
                      ),
                      itemBuilder: (context, index) {
                        final branch = filtered[index];
                        return _BranchCard(
                          branch: branch,
                          onEdit: () => _showAddEditBranchDialog(context, branch),
                          onDelete: () => _confirmDelete(context, branch),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditBranchDialog(BuildContext context, [BranchModel? branch]) {
    final colors = context.colors;
    final adminProv = context.read<AdminProvider>();
    final isEditing = branch != null;

    final nameCtrl = TextEditingController(text: branch?.name ?? '');
    final codeCtrl = TextEditingController(text: branch?.code ?? '');
    final addrCtrl = TextEditingController(text: branch?.address ?? '');
    String selectedBrandId = branch?.brandId ?? (adminProv.brands.isNotEmpty ? adminProv.brands.first.id : '');
    String status = branch?.status ?? 'operational';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            context.tr(isEditing ? 'Edit Branch' : 'Add Branch'),
            style: AppTypography.h3Of(context),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedBrandId.isNotEmpty ? selectedBrandId : null,
                    decoration: InputDecoration(
                      labelText: context.tr('Select Brand'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    dropdownColor: colors.surfaceElevated,
                    items: adminProv.brands
                        .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedBrandId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: context.tr('Branch Name'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Branch Code (e.g. CAI-MOA)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addrCtrl,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: context.tr('Address'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: context.tr('Status'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    dropdownColor: colors.surfaceElevated,
                    items: [
                      DropdownMenuItem(value: 'operational', child: Text(context.tr('Healthy'))),
                      DropdownMenuItem(value: 'alert', child: Text(context.tr('Warning'))),
                      DropdownMenuItem(value: 'degraded', child: Text(context.tr('Critical'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => status = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(context.tr('Cancel'), style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || selectedBrandId.isEmpty) return;
                final br = adminProv.brands.firstWhere((b) => b.id == selectedBrandId);
                if (isEditing) {
                  adminProv.updateBranch(
                    branch.copyWith(
                      brandId: br.id,
                      companyId: br.companyId,
                      name: nameCtrl.text.trim(),
                      code: codeCtrl.text.trim().isEmpty ? 'BR-01' : codeCtrl.text.trim(),
                      address: addrCtrl.text.trim(),
                      status: status,
                    ),
                  );
                } else {
                  adminProv.addBranch(
                    BranchModel(
                      id: 'branch-${DateTime.now().millisecondsSinceEpoch}',
                      companyId: br.companyId,
                      brandId: br.id,
                      name: nameCtrl.text.trim(),
                      code: codeCtrl.text.trim().isEmpty ? 'BR-01' : codeCtrl.text.trim(),
                      address: addrCtrl.text.trim().isEmpty ? 'Main Retail District' : addrCtrl.text.trim(),
                      cameraCount: 4,
                      onlineCameraCount: 4,
                      activeIncidentCount: 0,
                      status: status,
                    ),
                  );
                }
                Navigator.of(dialogCtx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr(isEditing ? 'Save Changes' : 'Add Branch')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BranchModel branch) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(context.tr('Delete Branch'), style: AppTypography.h3Of(context)),
        content: Text(
          '${context.tr("Are you sure?")} (${branch.name})\n${context.tr("This action cannot be undone")}',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminProvider>().deleteBranch(branch.id);
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: colors.error, foregroundColor: Colors.white),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BranchCard({
    required this.branch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color statusColor;
    String statusLabel;
    switch (branch.status) {
      case 'operational':
        statusColor = colors.success;
        statusLabel = context.tr('Healthy');
        break;
      case 'alert':
        statusColor = colors.warning;
        statusLabel = context.tr('Warning');
        break;
      case 'degraded':
      default:
        statusColor = colors.error;
        statusLabel = context.tr('Critical');
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Code Badge, Status Badge & Actions Popup
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    branch.code,
                    style: AppTypography.code.copyWith(
                      fontSize: 11,
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  color: colors.surfaceElevated,
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colors.border),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 15, color: colors.textPrimary),
                          const SizedBox(width: 8),
                          Text(context.tr('Edit'), style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 15, color: colors.error),
                          const SizedBox(width: 8),
                          Text(context.tr('Delete'), style: TextStyle(color: colors.error, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Branch Name & Address
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.name,
                  style: AppTypography.h3Of(context).copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        branch.address,
                        style: AppTypography.captionOf(context).copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Divider(height: 16, color: colors.borderSubtle),

            // Bottom Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BranchStat(
                  label: context.tr('Cameras'),
                  value: '${branch.onlineCameraCount}/${branch.cameraCount}',
                  color: colors.primary,
                  colors: colors,
                ),
                _BranchStat(
                  label: context.tr('Active Incidents'),
                  value: '${branch.activeIncidentCount}',
                  color: branch.activeIncidentCount > 0 ? colors.warning : colors.success,
                  colors: colors,
                ),
                _BranchStat(
                  label: context.tr('Stream Health'),
                  value: branch.isOperational ? '100%' : '75%',
                  color: statusColor,
                  colors: colors,
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
  final AppSemanticColors colors;

  const _BranchStat({
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
