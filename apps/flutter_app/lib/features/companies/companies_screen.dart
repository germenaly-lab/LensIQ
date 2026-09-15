import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_locale_provider.dart';
import '../../models/company.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({Key? key}) : super(key: key);

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final adminProv = context.watch<AdminProvider>();
    final companies = adminProv.companies.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.slug.toLowerCase().contains(q);
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/companies',
      title: 'Company Management',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddEditCompanyDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: Text(context.tr('Add Company')),
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
            // Search & Filters Header Bar
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
                        hintText: context.tr('Search companies...'),
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: 16, color: colors.textMuted),
                      onPressed: () => setState(() => _searchQuery = ''),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Companies List
            Expanded(
              child: companies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.corporate_fare_outlined, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('No data found'),
                            style: AppTypography.bodyOf(context).copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: companies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final company = companies[index];
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
                                    color: colors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.corporate_fare, color: colors.primary, size: 26),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            company.name,
                                            style: AppTypography.h3Of(context).copyWith(fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colors.secondary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              context.tr('Enterprise Tier'),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: colors.secondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Slug: ${company.slug} • Tenant ID: ${company.id}',
                                        style: AppTypography.captionOf(context).copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                _MetricBadge(
                                  label: context.tr('Brands'),
                                  value: '${company.brandCount}',
                                  colors: colors,
                                ),
                                const SizedBox(width: 12),
                                _MetricBadge(
                                  label: context.tr('Branches'),
                                  value: '${company.branchCount}',
                                  colors: colors,
                                ),
                                const SizedBox(width: 12),
                                _MetricBadge(
                                  label: context.tr('Cameras'),
                                  value: '${company.cameraCount}',
                                  colors: colors,
                                ),
                                const SizedBox(width: 16),
                                // Actions Popup
                                PopupMenuButton<String>(
                                  color: colors.surfaceElevated,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: colors.border),
                                  ),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddEditCompanyDialog(context, company);
                                    } else if (val == 'delete') {
                                      _confirmDelete(context, company);
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

  void _showAddEditCompanyDialog(BuildContext context, [CompanyModel? company]) {
    final colors = context.colors;
    final nameCtrl = TextEditingController(text: company?.name ?? '');
    final slugCtrl = TextEditingController(text: company?.slug ?? '');
    final isEditing = company != null;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          context.tr(isEditing ? 'Edit Company' : 'Add Company'),
          style: AppTypography.h3Of(context),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: context.tr('Company Name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: slugCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Slug (e.g. ego-holding)',
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
              if (nameCtrl.text.trim().isEmpty) return;
              final adminProv = context.read<AdminProvider>();
              if (isEditing) {
                adminProv.updateCompany(
                  company.copyWith(
                    name: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim().isEmpty
                        ? nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-')
                        : slugCtrl.text.trim(),
                  ),
                );
              } else {
                adminProv.addCompany(
                  CompanyModel(
                    id: 'comp-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim().isEmpty
                        ? nameCtrl.text.trim().toLowerCase().replaceAll(' ', '-')
                        : slugCtrl.text.trim(),
                    brandCount: 1,
                    branchCount: 3,
                    cameraCount: 12,
                    createdAt: DateTime.now(),
                  ),
                );
              }
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr(isEditing ? 'Save Changes' : 'Add Company')),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CompanyModel company) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(context.tr('Delete Company'), style: AppTypography.h3Of(context)),
        content: Text(
          '${context.tr("Are you sure?")} (${company.name})\n${context.tr("This action cannot be undone")}',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminProvider>().deleteCompany(company.id);
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

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final AppSemanticColors colors;

  const _MetricBadge({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
        ],
      ),
    );
  }
}
