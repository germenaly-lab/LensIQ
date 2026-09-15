import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_locale_provider.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/language_toggle_button.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@lensiq.cloud');
  final _passwordController = TextEditingController(text: 'password123');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final customPass = prefs.getString('lensiq_admin_password');
      if (customPass != null && mounted) {
        setState(() {
          _passwordController.text = customPass;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;
    final themeProv = context.watch<ThemeProvider>();
    final localeProv = context.watch<AppLocaleProvider>();

    return Directionality(
      textDirection: localeProv.textDirection,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            const LanguageToggleButton(),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                themeProv.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: colors.textSecondary,
                size: 20,
              ),
              tooltip: context.tr('Toggle Theme'),
              onPressed: () => themeProv.toggleTheme(),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: colors.cardShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Title
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.security, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('LensIQ Enterprise'),
                      style: AppTypography.h1Of(context).copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('AI Surveillance & Anomaly Detection'),
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Error Banner
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.error.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: colors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: TextStyle(color: colors.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Email Field
                    Text(
                      context.tr('Email'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, size: 18, color: colors.textMuted),
                        hintText: 'name@company.com',
                        hintStyle: TextStyle(color: colors.textMuted),
                        filled: true,
                        fillColor: colors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? context.tr('Please enter email and password') : null,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Text(
                      context.tr('Password'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline, size: 18, color: colors.textMuted),
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: colors.textMuted),
                        filled: true,
                        fillColor: colors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? context.tr('Please enter email and password') : null,
                    ),
                    const SizedBox(height: 22),

                    // Sign In Button
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              context.tr('Sign In'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Demo Role Login Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.borderSubtle)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.tr('Quick Demo Accounts').toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.textMuted),
                          ),
                        ),
                        Expanded(child: Divider(color: colors.borderSubtle)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Demo Accounts
                    _DemoRoleButton(
                      title: context.tr('Super Admin'),
                      subtitle: context.tr('Global Access'),
                      icon: Icons.admin_panel_settings_outlined,
                      color: colors.secondary,
                      colors: colors,
                      onTap: () => auth.switchDemoRole(UserRole.superAdmin),
                    ),
                    const SizedBox(height: 8),
                    _DemoRoleButton(
                      title: context.tr('Brand Manager'),
                      subtitle: context.tr('Brand Scoped'),
                      icon: Icons.storefront_outlined,
                      color: colors.primary,
                      colors: colors,
                      onTap: () => auth.switchDemoRole(UserRole.brandManager),
                    ),
                    const SizedBox(height: 8),
                    _DemoRoleButton(
                      title: context.tr('Branch Security'),
                      subtitle: context.tr('Branch Scoped'),
                      icon: Icons.security_outlined,
                      color: colors.warning,
                      colors: colors,
                      onTap: () => auth.switchDemoRole(UserRole.branchSecurity),
                    ),
                    const SizedBox(height: 24),

                    // POM Agency Attribution
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () async {
                        final uri = Uri.parse('https://pom-agency.online');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('Developed by POM Agency'),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 11, color: colors.textMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoRoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AppSemanticColors colors;
  final VoidCallback onTap;

  const _DemoRoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
