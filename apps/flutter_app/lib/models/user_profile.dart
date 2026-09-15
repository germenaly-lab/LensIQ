enum UserRole {
  superAdmin,
  brandManager,
  branchSecurity;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.brandManager:
        return 'Brand Manager';
      case UserRole.branchSecurity:
        return 'Branch Security';
    }
  }

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.branchSecurity;
    final r = role.toLowerCase().replaceAll(' ', '_');
    if (r == 'super_admin') return UserRole.superAdmin;
    if (r == 'brand_manager' || r == 'company_admin') return UserRole.brandManager;
    if (r == 'branch_security' || r == 'branch_manager' || r == 'viewer') return UserRole.branchSecurity;
    return UserRole.branchSecurity;
  }
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? companyId;
  final String? companyName;
  final String? brandId;
  final String? brandName;
  final String? branchId;
  final String? branchName;
  final List<String> authorizedBranchIds;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.companyId,
    this.companyName,
    this.brandId,
    this.brandName,
    this.branchId,
    this.branchName,
    this.authorizedBranchIds = const [],
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isBrandManager => role == UserRole.brandManager;
  bool get isBranchSecurity => role == UserRole.branchSecurity;

  bool canAccessBrand(String targetBrandId) {
    if (isSuperAdmin) return true;
    return brandId == targetBrandId;
  }

  bool canAccessBranch(String targetBranchId) {
    if (isSuperAdmin) return true;
    if (isBrandManager) {
      return authorizedBranchIds.contains(targetBranchId) || branchId == targetBranchId;
    }
    return (branchId == targetBranchId) || authorizedBranchIds.contains(targetBranchId);
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String?;
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? 'Authorized User',
      role: UserRole.fromString(rawRole),
      companyId: json['company_id'],
      companyName: json['company_name'],
      brandId: json['brand_id'],
      brandName: json['brand_name'],
      branchId: json['branch_id'],
      branchName: json['branch_name'],
      authorizedBranchIds: (json['authorized_branch_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.name,
        'company_id': companyId,
        'company_name': companyName,
        'brand_id': brandId,
        'brand_name': brandName,
        'branch_id': branchId,
        'branch_name': branchName,
        'authorized_branch_ids': authorizedBranchIds,
      };
}
