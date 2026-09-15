import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/company.dart';
import '../models/brand.dart';
import '../models/branch.dart';
import '../models/ai_rule.dart';
import '../models/audit_log.dart';
import '../models/roi.dart';
import '../models/user_profile.dart';
import '../services/mock_data_service.dart';

class AdminProvider extends ChangeNotifier {
  List<CompanyModel> _companies = [];
  List<BrandModel> _brands = [];
  List<BranchModel> _branches = [];
  List<AiRuleModel> _rules = [];
  List<AuditLogModel> _auditLogs = [];
  List<RoiPolygon> _rois = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Real-time update stream subscription
  Timer? _realtimeHeartbeat;
  bool _realtimeConnected = true;

  AdminProvider() {
    loadAllAdminData();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _realtimeHeartbeat?.cancel();
    super.dispose();
  }

  // Getters
  List<CompanyModel> get companies => _companies;
  List<BrandModel> get brands => _brands;
  List<BranchModel> get branches => _branches;
  List<AiRuleModel> get rules => _rules;
  List<AuditLogModel> get auditLogs => _auditLogs;
  List<RoiPolygon> get rois => _rois;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get realtimeConnected => _realtimeConnected;

  int get totalCompaniesCount => _companies.length;
  int get totalBrandsCount => _brands.length;
  int get totalBranchesCount => _branches.length;
  int get totalRulesCount => _rules.length;
  int get activeRulesCount => _rules.where((r) => r.enabled).length;

  Future<void> loadAllAdminData([UserProfile? user]) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (user != null) {
        _companies = user.isSuperAdmin
            ? List.from(MockDataService.demoCompanies)
            : MockDataService.demoCompanies.where((c) => c.id == user.companyId).toList();
        _brands = MockDataService.getBrandsForUser(user);
        _branches = MockDataService.getBranchesForUser(user);
        _rules = MockDataService.getRulesForUser(user);
      } else {
        _companies = List.from(MockDataService.demoCompanies);
        _brands = List.from(MockDataService.demoBrands);
        _branches = List.from(MockDataService.demoBranches);
        _rules = List.from(MockDataService.demoRules);
      }
      _auditLogs = List.from(MockDataService.demoAuditLogs);
      _rois = List.from(MockDataService.demoRois);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeListener() {
    _realtimeHeartbeat?.cancel();
    // Simulate real-time background ping/stream every 25 seconds
    _realtimeHeartbeat = Timer.periodic(const Duration(seconds: 25), (timer) {
      _realtimeConnected = true;
      notifyListeners();
    });
  }

  // --- Rule Management ---
  void addRule(AiRuleModel rule) {
    _rules.insert(0, rule);
    _recordAudit(
      action: 'AI Rule created',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Created rule "${rule.name}" for ${rule.cameraName} (${rule.ruleType}).',
      category: 'rule',
    );
    notifyListeners();
  }

  void updateRule(AiRuleModel rule) {
    final idx = _rules.indexWhere((r) => r.id == rule.id);
    if (idx != -1) {
      _rules[idx] = rule;
      _recordAudit(
        action: 'AI Rule updated',
        actorName: 'Alex Vance (Super Admin)',
        actorRole: 'super_admin',
        details: 'Modified parameters for rule "${rule.name}" (duration: ${rule.durationSeconds}s).',
        category: 'rule',
      );
      notifyListeners();
    }
  }

  void toggleRuleEnabled(String ruleId) {
    final idx = _rules.indexWhere((r) => r.id == ruleId);
    if (idx != -1) {
      final updated = _rules[idx].copyWith(enabled: !_rules[idx].enabled);
      _rules[idx] = updated;
      _recordAudit(
        action: updated.enabled ? 'AI Rule enabled' : 'AI Rule disabled',
        actorName: 'Alex Vance (Super Admin)',
        actorRole: 'super_admin',
        details: 'Rule "${updated.name}" toggled to ${updated.enabled ? "ACTIVE" : "INACTIVE"}.',
        category: 'rule',
      );
      notifyListeners();
    }
  }

  // --- ROI Management ---
  RoiPolygon? getRoiById(String roiId) {
    try {
      return _rois.firstWhere((r) => r.id == roiId);
    } catch (_) {
      return null;
    }
  }

  void saveRoi(RoiPolygon roi) {
    final idx = _rois.indexWhere((r) => r.id == roi.id);
    if (idx != -1) {
      _rois[idx] = roi;
    } else {
      _rois.add(roi);
    }
    _recordAudit(
      action: 'ROI modified',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Region of Interest "${roi.name}" updated with ${roi.points.length} vertices.',
      category: 'roi',
    );
    notifyListeners();
  }

  // --- Company Management ---
  void addCompany(CompanyModel company) {
    _companies.insert(0, company);
    _recordAudit(
      action: 'Company created',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Created enterprise tenant "${company.name}" (Slug: ${company.slug}).',
      category: 'company',
    );
    notifyListeners();
  }

  void updateCompany(CompanyModel company) {
    final idx = _companies.indexWhere((c) => c.id == company.id);
    if (idx != -1) {
      _companies[idx] = company;
      _recordAudit(
        action: 'Company updated',
        actorName: 'Alex Vance (Super Admin)',
        actorRole: 'super_admin',
        details: 'Updated details for company "${company.name}".',
        category: 'company',
      );
      notifyListeners();
    }
  }

  void deleteCompany(String companyId) {
    final company = _companies.firstWhere((c) => c.id == companyId, orElse: () => _companies.first);
    _companies.removeWhere((c) => c.id == companyId);
    _recordAudit(
      action: 'Company deleted',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Removed enterprise tenant "${company.name}".',
      category: 'company',
    );
    notifyListeners();
  }

  // --- Brand Management ---
  void addBrand(BrandModel brand) {
    _brands.insert(0, brand);
    _recordAudit(
      action: 'Brand created',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Created brand "${brand.name}" under company "${brand.companyName}".',
      category: 'brand',
    );
    notifyListeners();
  }

  void updateBrand(BrandModel brand) {
    final idx = _brands.indexWhere((b) => b.id == brand.id);
    if (idx != -1) {
      _brands[idx] = brand;
      _recordAudit(
        action: 'Brand updated',
        actorName: 'Alex Vance (Super Admin)',
        actorRole: 'super_admin',
        details: 'Updated details for brand "${brand.name}".',
        category: 'brand',
      );
      notifyListeners();
    }
  }

  void deleteBrand(String brandId) {
    final brand = _brands.firstWhere((b) => b.id == brandId, orElse: () => _brands.first);
    _brands.removeWhere((b) => b.id == brandId);
    _recordAudit(
      action: 'Brand deleted',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Removed brand "${brand.name}".',
      category: 'brand',
    );
    notifyListeners();
  }

  // --- Branch Management ---
  void addBranch(BranchModel branch) {
    _branches.insert(0, branch);
    _recordAudit(
      action: 'Branch created',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Created branch "${branch.name}" (Code: ${branch.code}).',
      category: 'branch',
    );
    notifyListeners();
  }

  void updateBranch(BranchModel branch) {
    final idx = _branches.indexWhere((b) => b.id == branch.id);
    if (idx != -1) {
      _branches[idx] = branch;
      _recordAudit(
        action: 'Branch updated',
        actorName: 'Alex Vance (Super Admin)',
        actorRole: 'super_admin',
        details: 'Updated details for branch "${branch.name}" (Status: ${branch.status}).',
        category: 'branch',
      );
      notifyListeners();
    }
  }

  void deleteBranch(String branchId) {
    final branch = _branches.firstWhere((b) => b.id == branchId, orElse: () => _branches.first);
    _branches.removeWhere((b) => b.id == branchId);
    _recordAudit(
      action: 'Branch deleted',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Removed branch "${branch.name}".',
      category: 'branch',
    );
    notifyListeners();
  }

  // --- Audit Trail ---
  void _recordAudit({
    required String action,
    required String actorName,
    required String actorRole,
    required String details,
    required String category,
  }) {
    final log = AuditLogModel(
      id: 'aud-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      action: action,
      actorName: actorName,
      actorRole: actorRole,
      details: details,
      category: category,
      ipAddress: '192.168.1.102',
    );
    _auditLogs.insert(0, log);
  }
}
