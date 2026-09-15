import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_locale_provider.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/responsive_scaffold.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _search = '';
  UserRole? _selectedRoleFilter;
  late List<UserProfile> _users;

  @override
  void initState() {
    super.initState();
    _users = List.from(MockDataService.demoUsers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final custom = context.read<AuthProvider>().getCustomUsers();
      for (final u in custom) {
        if (!_users.any((x) => x.email.toLowerCase() == u.email.toLowerCase())) {
          setState(() {
            _users.insert(0, u);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final filteredUsers = _users.where((u) {
      if (_selectedRoleFilter != null && u.role != _selectedRoleFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.brandName?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/users',
      title: 'User Management',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context),
          icon: const Icon(Icons.person_add, size: 16),
          label: Text(context.tr('Add User')),
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
            // Controls Bar
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
                        hintText: context.tr('Search users...'),
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _search = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<UserRole?>(
                    value: _selectedRoleFilter,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.surfaceElevated,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                    hint: Text(context.tr('Role'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.tr('Role'))),
                      DropdownMenuItem(value: UserRole.superAdmin, child: Text(context.tr('Super Admin'))),
                      DropdownMenuItem(value: UserRole.brandManager, child: Text(context.tr('Brand Manager'))),
                      DropdownMenuItem(value: UserRole.branchSecurity, child: Text(context.tr('Branch Security'))),
                    ],
                    onChanged: (val) => setState(() => _selectedRoleFilter = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Users List
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text(context.tr('No data found'), style: TextStyle(color: colors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final roleColor = _getRoleColor(user.role, colors);

                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                            boxShadow: colors.cardShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: colors.primaryContainer,
                                  child: Text(
                                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user.fullName,
                                            style: AppTypography.h3Of(context).copyWith(fontSize: 15),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: roleColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              context.tr(user.role.displayName).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: roleColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${user.email} • ${user.companyName ?? "Ego Retail Holding"} ${user.brandName != null ? "• ${user.brandName}" : ""}',
                                        style: AppTypography.captionOf(context).copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: colors.borderSubtle),
                                  ),
                                  child: Text(
                                    '${user.authorizedBranchIds.length} ${context.tr("Branches")}',
                                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _showChangeUserPasswordDialog(context, user),
                                  icon: const Icon(Icons.vpn_key_outlined, size: 13),
                                  label: Text(context.tr('Change Password'), style: const TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary.withOpacity(0.35)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  void _showChangeUserPasswordDialog(BuildContext context, UserProfile user) {
    final colors = context.colors;
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String? localError;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('Change Password')}: ${user.fullName}',
                  style: AppTypography.h3Of(context).copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.primaryContainer,
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(user.email, style: TextStyle(color: colors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.tr(user.role.displayName),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: context.tr('New Password'),
                    prefixIcon: Icon(Icons.lock_outline, size: 18, color: colors.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: context.tr('Confirm New Password'),
                    prefixIcon: Icon(Icons.check_circle_outline, size: 18, color: colors.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    localError!,
                    style: TextStyle(color: colors.error, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(context.tr('Cancel'), style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final p1 = newPassCtrl.text.trim();
                      final p2 = confirmPassCtrl.text.trim();
                      if (p1.isEmpty || p2.isEmpty) {
                        setDialogState(() => localError = context.tr('Please fill in all password fields'));
                        return;
                      }
                      if (p1.length < 6) {
                        setDialogState(() => localError = context.tr('Password must be at least 6 characters'));
                        return;
                      }
                      if (p1 != p2) {
                        setDialogState(() => localError = context.tr('New passwords do not match'));
                        return;
                      }
                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });

                      final ok = await context.read<AuthProvider>().resetUserPassword(user.email, p1);
                      if (ok) {
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${context.tr("Password updated successfully!")} (${user.fullName})'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        setDialogState(() {
                          isSaving = false;
                          localError = context.read<AuthProvider>().errorMessage ?? 'Failed to update password';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('Update Password')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final colors = context.colors;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'password123');
    UserRole selectedRole = UserRole.superAdmin;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          title: Text(context.tr('Add User'), style: AppTypography.h3Of(context)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: context.tr('Full Name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: context.tr('Email'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: context.tr('Password'),
                    hintText: 'Default: password123',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: context.tr('Role'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  dropdownColor: colors.surfaceElevated,
                  items: [
                    DropdownMenuItem(
                      value: UserRole.superAdmin,
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 16, color: colors.secondary),
                          const SizedBox(width: 8),
                          Text('${context.tr('Super Admin')} (${context.tr('General Manager')})'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: UserRole.brandManager,
                      child: Row(
                        children: [
                          Icon(Icons.storefront, size: 16, color: colors.primary),
                          const SizedBox(width: 8),
                          Text(context.tr('Brand Manager')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: UserRole.branchSecurity,
                      child: Row(
                        children: [
                          Icon(Icons.security, size: 16, color: colors.warning),
                          const SizedBox(width: 8),
                          Text(context.tr('Branch Security')),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                if (selectedRole == UserRole.superAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: colors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('General Manager has full privileges across all companies, branches, cameras, and users.'),
                            style: TextStyle(fontSize: 11, color: colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                final allBranchIds = context.read<AdminProvider>().branches.map((b) => b.id).toList();
                final newUser = UserProfile(
                  id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
                  email: emailCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  role: selectedRole,
                  companyId: 'comp-1',
                  companyName: 'Ego Retail Holding',
                  brandId: selectedRole == UserRole.brandManager ? 'brand-1' : null,
                  brandName: selectedRole == UserRole.brandManager ? 'Ego Fashion' : null,
                  branchId: selectedRole == UserRole.branchSecurity ? 'branch-1' : null,
                  branchName: selectedRole == UserRole.branchSecurity ? 'Mall of Arabia' : null,
                  authorizedBranchIds: selectedRole == UserRole.superAdmin
                      ? (allBranchIds.isNotEmpty ? allBranchIds : ['branch-1', 'branch-2', 'branch-3'])
                      : ['branch-1'],
                );
                context.read<AuthProvider>().registerUser(newUser, passwordCtrl.text.trim());
                setState(() {
                  _users.insert(0, newUser);
                });
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${context.tr("Action completed successfully")} (${newUser.fullName})'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(context.tr('Save')),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role, AppSemanticColors colors) {
    switch (role) {
      case UserRole.superAdmin:
        return colors.secondary;
      case UserRole.brandManager:
        return colors.primary;
      case UserRole.branchSecurity:
        return colors.warning;
    }
  }
}
