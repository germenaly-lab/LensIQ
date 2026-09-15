class BrandModel {
  final String id;
  final String companyId;
  final String companyName;
  final String name;
  final String slug;
  final int branchCount;
  final int cameraCount;
  final int activeIncidents;

  const BrandModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.slug,
    this.branchCount = 0,
    this.cameraCount = 0,
    this.activeIncidents = 0,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      companyName: json['company_name'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      branchCount: json['branch_count'] ?? 0,
      cameraCount: json['camera_count'] ?? 0,
      activeIncidents: json['active_incidents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'company_name': companyName,
        'name': name,
        'slug': slug,
        'branch_count': branchCount,
        'camera_count': cameraCount,
        'active_incidents': activeIncidents,
      };
}
