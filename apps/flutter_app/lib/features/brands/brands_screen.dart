import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final brands = adminProv.brands;

    return ResponsiveScaffold(
      currentRoute: '/brands',
      title: 'Retail Brands',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retail brands under holding companies with isolated branch scopes.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: brands.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final brand = brands[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.storefront, color: AppColors.secondary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(brand.name, style: AppTypography.h3),
                                const SizedBox(height: 4),
                                Text(
                                  'Company: ${brand.companyName} • Slug: ${brand.slug}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          _BrandStatBadge(label: 'Branches', value: '${brand.branchCount}'),
                          const SizedBox(width: 14),
                          _BrandStatBadge(label: 'Cameras', value: '${brand.cameraCount}'),
                          const SizedBox(width: 14),
                          _BrandStatBadge(
                            label: 'Active Alerts',
                            value: '${brand.activeIncidents}',
                            color: brand.activeIncidents > 0 ? AppColors.warning : AppColors.success,
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

class _BrandStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _BrandStatBadge({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c)),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
