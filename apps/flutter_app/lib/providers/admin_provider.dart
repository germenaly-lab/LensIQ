import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company.dart';
import '../models/brand.dart';
import '../models/branch.dart';
import '../models/ai_rule.dart';
import '../models/audit_log.dart';
import '../models/roi.dart';
import '../models/user_profile.dart';
import '../services/mock_data_service.dart';

class AdminProvider extends ChangeNotifier {
  final SharedPreferences? _prefs;

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

  AdminProvider([this._prefs]) {
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
      // 1. Companies
      if (_prefs != null && _prefs!.containsKey('lensiq_companies')) {
        final raw = _prefs!.getString('lensiq_companies')!;
        final list = (jsonDecode(raw) as List).map((i) => CompanyModel.fromJson(i as Map<String, dynamic>)).toList();
        _companies = list;
      } else {
        _companies = (user != null && !user.isSuperAdmin)
            ? MockDataService.demoCompanies.where((c) => c.id == user.companyId).toList()
            : List.from(MockDataService.demoCompanies);
      }

      // 2. Brands
      if (_prefs != null && _prefs!.containsKey('lensiq_brands')) {
        final raw = _prefs!.getString('lensiq_brands')!;
        final list = (jsonDecode(raw) as List).map((i) => BrandModel.fromJson(i as Map<String, dynamic>)).toList();
        _brands = list;
      } else {
        _brands = user != null ? MockDataService.getBrandsForUser(user) : List.from(MockDataService.demoBrands);
      }

      // 3. Branches
      if (_prefs != null && _prefs!.containsKey('lensiq_branches')) {
        final raw = _prefs!.getString('lensiq_branches')!;
        final list = (jsonDecode(raw) as List).map((i) => BranchModel.fromJson(i as Map<String, dynamic>)).toList();
        _branches = list;
      } else {
        _branches = user != null ? MockDataService.getBranchesForUser(user) : List.from(MockDataService.demoBranches);
      }

      // 4. AI Rules
      if (_prefs != null && _prefs!.containsKey('lensiq_rules')) {
        final raw = _prefs!.getString('lensiq_rules')!;
        final list = (jsonDecode(raw) as List).map((i) => AiRuleModel.fromJson(i as Map<String, dynamic>)).toList();
        _rules = list;
      } else {
        _rules = user != null ? MockDataService.getRulesForUser(user) : List.from(MockDataService.demoRules);
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

  void _persistCompanies() {
    if (_prefs == null) return;
    final data = jsonEncode(_companies.map((c) => c.toJson()).toList());
    _prefs!.setString('lensiq_companies', data);
  }

  void _persistBrands() {
    if (_prefs == null) return;
    final data = jsonEncode(_brands.map((b) => b.toJson()).toList());
    _prefs!.setString('lensiq_brands', data);
  }

  void _persistBranches() {
    if (_prefs == null) return;
    final data = jsonEncode(_branches.map((b) => b.toJson()).toList());
    _prefs!.setString('lensiq_branches', data);
  }

  void _persistRules() {
    if (_prefs == null) return;
    final data = jsonEncode(_rules.map((r) => r.toJson()).toList());
    _prefs!.setString('lensiq_rules', data);
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
    _persistRules();
    _recordAudit(
      action: 'AI Rule created',
      actorName: 'Super Admin',
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
      _persistRules();
      _recordAudit(
        action: 'AI Rule updated',
        actorName: 'Super Admin',
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
      _persistRules();
      _recordAudit(
        action: updated.enabled ? 'AI Rule enabled' : 'AI Rule disabled',
        actorName: 'Super Admin',
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
      actorName: 'Super Admin',
      actorRole: 'super_admin',
      details: 'Region of Interest "${roi.name}" updated with ${roi.points.length} vertices.',
      category: 'roi',
    );
    notifyListeners();
  }

  // --- Company Management ---
  void addCompany(CompanyModel company) {
    _companies.insert(0, company);
    _persistCompanies();
    _recordAudit(
      action: 'Company created',
      actorName: 'Super Admin',
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
      _persistCompanies();
      _recordAudit(
        action: 'Company updated',
        actorName: 'Super Admin',
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
    _persistCompanies();
    _recordAudit(
      action: 'Company deleted',
      actorName: 'Super Admin',
      actorRole: 'super_admin',
      details: 'Removed enterprise tenant "${company.name}".',
      category: 'company',
    );
    notifyListeners();
  }

  // --- Brand Management ---
  void addBrand(BrandModel brand) {
    _brands.insert(0, brand);
    _persistBrands();
    _recordAudit(
      action: 'Brand created',
      actorName: 'Super Admin',
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
      _persistBrands();
      _recordAudit(
        action: 'Brand updated',
        actorName: 'Super Admin',
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
    _persistBrands();
    _recordAudit(
      action: 'Brand deleted',
      actorName: 'Super Admin',
      actorRole: 'super_admin',
      details: 'Removed brand "${brand.name}".',
      category: 'brand',
    );
    notifyListeners();
  }

  // --- Branch Management ---
  void addBranch(BranchModel branch) {
    _branches.insert(0, branch);
    _persistBranches();
    _recordAudit(
      action: 'Branch created',
      actorName: 'Super Admin',
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
      _persistBranches();
      _recordAudit(
        action: 'Branch updated',
        actorName: 'Super Admin',
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
    _persistBranches();
    _recordAudit(
      action: 'Branch deleted',
      actorName: 'Super Admin',
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
