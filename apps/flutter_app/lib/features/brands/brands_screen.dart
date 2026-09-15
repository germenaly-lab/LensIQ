import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_locale_provider.dart';
import '../../models/brand.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({Key? key}) : super(key: key);

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  String _searchQuery = '';
  String? _selectedCompanyFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final adminProv = context.watch<AdminProvider>();

    final filteredBrands = adminProv.brands.where((b) {
      if (_selectedCompanyFilter != null && b.companyId != _selectedCompanyFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
          b.companyName.toLowerCase().contains(q) ||
          b.slug.toLowerCase().contains(q);
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/brands',
      title: 'Brand Management',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddEditBrandDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: Text(context.tr('Add Brand')),
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
            // Filter Bar
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
                        hintText: context.tr('Search brands...'),
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String?>(
                    value: _selectedCompanyFilter,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.surfaceElevated,
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    hint: Text(context.tr('All Companies'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(context.tr('All Companies')),
                      ),
                      ...adminProv.companies.map(
                        (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedCompanyFilter = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Brands List
            Expanded(
              child: filteredBrands.isEmpty
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
                  : ListView.separated(
                      itemCount: filteredBrands.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final brand = filteredBrands[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                            boxShadow: colors.cardShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colors.secondary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.storefront, color: colors.secondary, size: 26),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            brand.name,
                                            style: AppTypography.h3Of(context).copyWith(fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colors.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              brand.companyName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: colors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Slug: ${brand.slug} • Brand ID: ${brand.id}',
                                        style: AppTypography.captionOf(context).copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                _BrandStatBadge(
                                  label: context.tr('Branches'),
                                  value: '${brand.branchCount}',
                                  colors: colors,
                                ),
                                const SizedBox(width: 12),
                                _BrandStatBadge(
                                  label: context.tr('Cameras'),
                                  value: '${brand.cameraCount}',
                                  colors: colors,
                                ),
                                const SizedBox(width: 12),
                                _BrandStatBadge(
                                  label: context.tr('Active Incidents'),
                                  value: '${brand.activeIncidents}',
                                  color: brand.activeIncidents > 0 ? colors.warning : colors.success,
                                  colors: colors,
                                ),
                                const SizedBox(width: 16),
                                PopupMenuButton<String>(
                                  color: colors.surfaceElevated,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: colors.border),
                                  ),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddEditBrandDialog(context, brand);
                                    } else if (val == 'delete') {
                                      _confirmDelete(context, brand);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 16, color: colors.textPrimary),
                                          const SizedBox(width: 8),
                                          Text(context.tr('Edit'), style: TextStyle(color: colors.textPrimary)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 16, color: colors.error),
                                          const SizedBox(width: 8),
                                          Text(context.tr('Delete'), style: TextStyle(color: colors.error)),
                                        ],
                                      ),
                                    ),
                                  ],
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

  void _showAddEditBrandDialog(BuildContext context, [BrandModel? brand]) {
    final colors = context.colors;
    final adminProv = context.read<AdminProvider>();
    final isEditing = brand != null;

    final nameCtrl = TextEditingController(text: brand?.name ?? '');
    final slugCtrl = TextEditingController(text: brand?.slug ?? '');
    String selectedCompId = brand?.companyId ?? (adminProv.companies.isNotEmpty ? adminProv.companies.first.id : '');

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
            context.tr(isEditing ? 'Edit Brand' : 'Add Brand'),
            style: AppTypography.h3Of(context),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCompId.isNotEmpty ? selectedCompId : null,
                  decoration: InputDecoration(
                    labelText: context.tr('Select Company'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  dropdownColor: colors.surfaceElevated,
                  items: adminProv.companies
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCompId = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: context.tr('Brand Name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: slugCtrl,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Slug (e.g. ego-fashion)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(context.tr('Cancel'), style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || selectedCompId.isEmpty) return;
                final comp = adminProv.companies.firstWhere((c) => c.id == selectedCompId);
                if (isEditing) {
                  adminProv.updateBrand(
                    brand.copyWith(
                      companyId: comp.id,
                      companyName: comp.name,
                      name: nameCtrl.text.trim(),
                      slug: slugCtrl.text.trim().isEmpty
                          ? nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-')
                          : slugCtrl.text.trim(),
                    ),
                  );
                } else {
                  adminProv.addBrand(
                    BrandModel(
                      id: 'brand-${DateTime.now().millisecondsSinceEpoch}',
                      companyId: comp.id,
                      companyName: comp.name,
                      name: nameCtrl.text.trim(),
                      slug: slugCtrl.text.trim().isEmpty
                          ? nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-')
                          : slugCtrl.text.trim(),
                      branchCount: 2,
                      cameraCount: 6,
                      activeIncidents: 0,
                    ),
                  );
                }
                Navigator.of(dialogCtx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr(isEditing ? 'Save Changes' : 'Add Brand')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BrandModel brand) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(context.tr('Delete Brand'), style: AppTypography.h3Of(context)),
        content: Text(
          '${context.tr("Are you sure?")} (${brand.name})\n${context.tr("This action cannot be undone")}',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminProvider>().deleteBrand(brand.id);
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

class _BrandStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final AppSemanticColors colors;

  const _BrandStatBadge({
    required this.label,
    required this.value,
    this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? colors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c)),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
        ],
      ),
    );
  }
}
