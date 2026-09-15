class CompanyModel {
  final String id;
  final String name;
  final String slug;
  final int brandCount;
  final int branchCount;
  final int cameraCount;
  final DateTime createdAt;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.slug,
    this.brandCount = 0,
    this.branchCount = 0,
    this.cameraCount = 0,
    required this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      brandCount: json['brand_count'] ?? 0,
      branchCount: json['branch_count'] ?? 0,
      cameraCount: json['camera_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'brand_count': brandCount,
        'branch_count': branchCount,
        'camera_count': cameraCount,
        'created_at': createdAt.toIso8601String(),
      };
}
