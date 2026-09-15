import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/loading_view.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _backendUrlController;

  @override
  void initState() {
    super.initState();
    _backendUrlController = TextEditingController(text: AppConfig.backendBaseUrl);
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    super.dispose();
  }

  void _saveBackendUrl() {
    AppConfig.updateBackendUrl(_backendUrlController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backend API URL updated to: ${AppConfig.backendBaseUrl}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = context.watch<ThemeProvider>();

    if (user == null) return const Scaffold(body: LoadingView());

    return ResponsiveScaffold(
      currentRoute: '/settings',
      title: 'Platform Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Authenticated User Identity', style: AppTypography.h3),
                        const SizedBox(height: 16),
                        _SettingItem(label: 'Full Name', value: user.fullName),
                        _SettingItem(label: 'Work Email', value: user.email),
                        _SettingItem(label: 'Assigned Role', value: user.role.displayName),
                        _SettingItem(label: 'Tenant Company', value: user.companyName ?? 'Ego Retail Holding'),
                        if (user.brandName != null) _SettingItem(label: 'Retail Brand', value: user.brandName!),
                        if (user.branchName != null) _SettingItem(label: 'Assigned Branch', value: user.branchName!),
                        _SettingItem(
                          label: 'Authorized Scope',
                          value: '${user.authorizedBranchIds.length} branch(es) permitted',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Gateway & API Configuration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('API & Streaming Gateway Integration', style: AppTypography.h3),
                        const SizedBox(height: 14),
                        Text(
                          'Configure the Express backend API and Streaming Gateway base URLs.',
                          style: AppTypography.bodySecondary,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _backendUrlController,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Express Backend API URL',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save, color: AppColors.primary),
                              onPressed: _saveBackendUrl,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SettingItem(
                          label: 'Streaming Gateway URL',
                          value: AppConfig.streamingGatewayBaseUrl,
                        ),
                        _SettingItem(
                          label: 'Supabase Cloud Instance',
                          value: AppConfig.supabaseUrl,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Mobile Companion Apps (Staff & Security)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.phone_android, color: AppColors.secondary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('Staff Mobile Companion Apps', style: AppTypography.h3),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mobile apps are lightweight client applications for branch security guards and floor supervisors. They receive real-time push alerts, offline incident summaries, and cashier monitoring updates.',
                          style: AppTypography.bodySecondary,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.android, color: AppColors.success, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Android Staff Client (APK)', style: AppTypography.bodyMedium),
                                    SizedBox(height: 2),
                                    Text(
                                      'Direct install package for retail hand-held terminals and Android phones.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse('/downloads/app-debug.apk');
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Download APK'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.apple, color: AppColors.textPrimary, size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('iOS Companion App (iPhone & iPad)', style: AppTypography.bodyMedium),
                                    SizedBox(height: 2),
                                    Text(
                                      'Distributed via Apple TestFlight / Apple Business Manager for enterprise fleet.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('iOS TestFlight invitation links are sent via company MDM.'),
                                    ),
                                  );
                                },
                                child: const Text('Request Access'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Theme & Preferences
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Appearance & Theme', style: AppTypography.h3),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dark Theme (NOC Default)', style: AppTypography.bodyMedium),
                          subtitle: const Text('High-contrast dark palette for monitoring centers', style: AppTypography.caption),
                          value: theme.isDarkMode,
                          onChanged: (_) => theme.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Logout Action
                ElevatedButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out of Platform'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final String value;

  const _SettingItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
