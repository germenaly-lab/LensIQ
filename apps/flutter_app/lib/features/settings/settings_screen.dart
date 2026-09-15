import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/notification_preferences_dialog.dart';
import '../../models/notification_item.dart';
import '../../providers/notification_provider.dart';
import '../../core/localization/app_locale_provider.dart';
import '../../widgets/language_toggle_button.dart';

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
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.tr("Preferences saved")}: ${AppConfig.backendBaseUrl}'),
        backgroundColor: colors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = context.watch<ThemeProvider>();
    final colors = context.colors;

    if (user == null) return const Scaffold(body: LoadingView());

    return ResponsiveScaffold(
      currentRoute: '/settings',
      title: 'Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Profile Card
                _buildCard(
                  colors: colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('User Details'), style: AppTypography.h3Of(context)),
                      const SizedBox(height: 16),
                      _SettingItem(label: context.tr('Full Name'), value: user.fullName, colors: colors),
                      _SettingItem(label: context.tr('Email'), value: user.email, colors: colors),
                      _SettingItem(label: context.tr('Role'), value: context.tr(user.role.displayName), colors: colors),
                      _SettingItem(label: context.tr('Company'), value: user.companyName ?? 'Ego Retail Holding', colors: colors),
                      if (user.brandName != null)
                        _SettingItem(label: context.tr('Brand'), value: user.brandName!, colors: colors),
                      if (user.branchName != null)
                        _SettingItem(label: context.tr('Branch'), value: user.branchName!, colors: colors),
                      _SettingItem(
                        label: context.tr('Branches'),
                        value: '${user.authorizedBranchIds.length} ${context.tr("Branches")}',
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Gateway & API Configuration
                _buildCard(
                  colors: colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('Stream Quality'), style: AppTypography.h3Of(context)),
                      const SizedBox(height: 14),
                      Text(
                        'Configure the Express backend API and Streaming Gateway base URLs.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _backendUrlController,
                        style: TextStyle(fontSize: 14, color: colors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Express Backend API URL',
                          labelStyle: TextStyle(color: colors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.save, color: colors.primary),
                            onPressed: _saveBackendUrl,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SettingItem(
                        label: 'Streaming Gateway URL',
                        value: AppConfig.streamingGatewayBaseUrl,
                        colors: colors,
                      ),
                      _SettingItem(
                        label: 'Supabase Cloud Instance',
                        value: AppConfig.supabaseUrl,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Mobile Companion Apps (Staff & Security APK)
                _buildCard(
                  colors: colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.phone_android, color: colors.secondary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('Staff Mobile Companion App', style: AppTypography.h3Of(context)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lightweight client app for branch security guards and floor supervisors. Receives real-time push alerts, offline incident summaries, and cashier monitoring updates.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('/downloads/app-debug.apk');
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download Android APK (v1.0.0)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. In-App & Push Notification Preferences
                Consumer<NotificationProvider>(
                  builder: (context, notifProv, _) {
                    final prefs = notifProv.preferences;
                    return _buildCard(
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications_active, color: colors.warning, size: 22),
                              const SizedBox(width: 10),
                              Text(context.tr('Push Notifications'), style: AppTypography.h3Of(context)),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const NotificationPreferencesDialog(),
                                  );
                                },
                                icon: const Icon(Icons.tune, size: 16),
                                label: Text(context.tr('Configure Preferences')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Control real-time notifications for critical incidents, cashier alerts, and camera offline events.',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      prefs.inAppPushEnabled ? Icons.check_circle : Icons.cancel,
                                      color: prefs.inAppPushEnabled ? colors.success : colors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      prefs.inAppPushEnabled ? 'In-App Alerts: ACTIVE' : 'In-App Alerts: MUTED',
                                      style: TextStyle(
                                        color: prefs.inAppPushEnabled ? colors.success : colors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 16, color: colors.borderSubtle),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _StatusPill(label: context.tr('Critical'), isEnabled: prefs.criticalAlerts, color: colors.error, colors: colors),
                                    _StatusPill(label: context.tr('Warning'), isEnabled: prefs.warningAlerts, color: colors.warning, colors: colors),
                                    _StatusPill(label: context.tr('Info'), isEnabled: prefs.infoAlerts, color: colors.info, colors: colors),
                                    _StatusPill(label: context.tr('Camera stream offline'), isEnabled: prefs.cameraOffline, color: colors.warning, colors: colors),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                final testNotif = NotificationItem(
                                  id: 'notif_test_${DateTime.now().millisecondsSinceEpoch}',
                                  recipientId: user.id,
                                  incidentId: 'inc_cashier_test',
                                  title: 'CRITICAL: Cashier Area Empty',
                                  body: '${user.brandName ?? "Armani Exchange"} • ${user.branchName ?? "Mall of Arabia"} • Cashier 01: Unattended for 3 continuous minutes.',
                                  sentAt: DateTime.now(),
                                  deliveryStatus: 'delivered',
                                  data: {
                                    'severity': 'critical',
                                    'incidentId': 'inc_cashier_test',
                                    'route': '/incidents',
                                  },
                                );
                                notifProv.addIncomingNotification(testNotif);
                              },
                              icon: const Icon(Icons.send_outlined, size: 14),
                              label: const Text('Simulate In-App Push Alert', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 5. Language & Regional Localization
                Consumer<AppLocaleProvider>(
                  builder: (context, localeProv, child) {
                    return _buildCard(
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.language, color: colors.primary, size: 22),
                              const SizedBox(width: 10),
                              Text(context.tr('Language'), style: AppTypography.h3Of(context)),
                              const Spacer(),
                              const LanguageToggleButton(),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            localeProv.isArabic
                                ? 'اللغة الأصلية للمنصة هي الإنجليزية، ويمكنك التبديل إلى العربية في أي وقت لجميع القوائم والتنبيهات مع دعم كامل لتنسيق الاتجاه من اليمين إلى اليسار (RTL).'
                                : 'The default platform language is English. You can switch to Arabic at any time for all menus, navigation, and alerts with complete RTL layout support.',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ChoiceChip(
                                label: Text(context.tr('English (Default)')),
                                selected: !localeProv.isArabic,
                                onSelected: (selected) {
                                  if (selected) localeProv.setLanguage('en');
                                },
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: Text(context.tr('Arabic (العربية RTL)')),
                                selected: localeProv.isArabic,
                                onSelected: (selected) {
                                  if (selected) localeProv.setLanguage('ar');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 6. Appearance & Theme (Dark NOC vs Clean Light)
                _buildCard(
                  colors: colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('Appearance'), style: AppTypography.h3Of(context)),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          theme.isDarkMode
                              ? context.tr('Dark Theme (NOC Security)')
                              : context.tr('Light Theme (Clean Enterprise)'),
                          style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
                        ),
                        subtitle: Text(
                          theme.isDarkMode
                              ? 'High-contrast NOC security operations theme.'
                              : 'Clean, pristine enterprise light palette with zero dark patches.',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                        value: theme.isDarkMode,
                        onChanged: (_) => theme.toggleTheme(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Developer Attribution: POM Agency
                _buildCard(
                  colors: colors,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: colors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text('Platform Engineering & Attribution', style: AppTypography.h3Of(context)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'LensIQ Enterprise AI CCTV Monitoring System architecture, multi-stream gateway, and custom UI/UX engineered with precision.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () async {
                          final uri = Uri.parse('https://pom-agency.online');
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.primary.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public, size: 16, color: colors.primary),
                              const SizedBox(width: 8),
                              Text(
                                '${context.tr("Developed by POM Agency")} (pom-agency.online)',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.open_in_new, size: 14, color: colors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 8. Sign Out Button
                ElevatedButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(context.tr('Sign Out')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required AppSemanticColors colors, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final String value;
  final AppSemanticColors colors;

  const _SettingItem({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final Color color;
  final AppSemanticColors colors;

  const _StatusPill({
    required this.label,
    required this.isEnabled,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.12) : colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.5) : colors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isEnabled ? color : colors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isEnabled ? color : colors.textMuted,
              fontSize: 10,
              fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
