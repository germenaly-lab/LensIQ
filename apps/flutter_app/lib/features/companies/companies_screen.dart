import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class CompaniesScreen extends StatelessWidget {
  const CompaniesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final companies = adminProv.companies;

    return ResponsiveScaffold(
      currentRoute: '/companies',
      title: 'Tenant Companies',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multi-tenant holding companies registered in LensIQ.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: companies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final company = companies[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.corporate_fare, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(company.name, style: AppTypography.h3),
                                const SizedBox(height: 4),
                                Text(
                                  'Slug: ${company.slug} • Tenant ID: ${company.id}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          _MetricBadge(label: 'Brands', value: '${company.brandCount}'),
                          const SizedBox(width: 16),
                          _MetricBadge(label: 'Branches', value: '${company.branchCount}'),
                          const SizedBox(width: 16),
                          _MetricBadge(label: 'Cameras', value: '${company.cameraCount}'),
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

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
