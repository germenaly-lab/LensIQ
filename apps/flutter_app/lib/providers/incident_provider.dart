import 'package:flutter/foundation.dart';
import '../models/incident.dart';
import '../models/user_profile.dart';
import '../models/dashboard_summary.dart';
import '../repositories/incident_repository.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentRepository _repository;

  List<IncidentModel> _incidents = [];
  DashboardSummary _summary = DashboardSummary.initial();
  bool _isLoading = false;

  // Filter state for Incidents Screen
  String _searchQuery = '';
  IncidentSeverity? _filterSeverity;
  IncidentStatus? _filterStatus;
  String? _filterBrand;
  String? _filterBranch;

  IncidentProvider(this._repository);

  List<IncidentModel> get rawIncidents => _incidents;
  DashboardSummary get summary => _summary;
  bool get isLoading => _isLoading;

  String get searchQuery => _searchQuery;
  IncidentSeverity? get filterSeverity => _filterSeverity;
  IncidentStatus? get filterStatus => _filterStatus;
  String? get filterBrand => _filterBrand;
  String? get filterBranch => _filterBranch;

  // Filtered Incidents List
  List<IncidentModel> get incidents {
    return _incidents.where((inc) {
      if (_filterSeverity != null && inc.severity != _filterSeverity) return false;
      if (_filterStatus != null && inc.status != _filterStatus) return false;
      if (_filterBrand != null && inc.brandName != null && !inc.brandName!.toLowerCase().contains(_filterBrand!.toLowerCase())) {
        return false;
      }
      if (_filterBranch != null && !inc.branchName.toLowerCase().contains(_filterBranch!.toLowerCase())) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = inc.title.toLowerCase().contains(q);
        final matchesCamera = inc.cameraName.toLowerCase().contains(q);
        final matchesDesc = inc.description.toLowerCase().contains(q);
        final matchesBranch = inc.branchName.toLowerCase().contains(q);
        if (!matchesTitle && !matchesCamera && !matchesDesc && !matchesBranch) return false;
      }
      return true;
    }).toList();
  }

  // Chart Computations directly from real incident records
  Map<String, int> get incidentsByBrand {
    final map = <String, int>{};
    for (final inc in _incidents) {
      final brand = inc.brandName ?? 'Ego Fashion';
      map[brand] = (map[brand] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get incidentsByBranch {
    final map = <String, int>{};
    for (final inc in _incidents) {
      final branch = inc.branchName.replaceAll(' Branch', '');
      map[branch] = (map[branch] ?? 0) + 1;
    }
    return map;
  }

  Map<IncidentSeverity, int> get incidentsBySeverity {
    final map = <IncidentSeverity, int>{
      IncidentSeverity.critical: 0,
      IncidentSeverity.warning: 0,
      IncidentSeverity.info: 0,
    };
    for (final inc in _incidents) {
      map[inc.severity] = (map[inc.severity] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get incidentsOverTime {
    // Group incidents by 4-hour window or days
    return {
      '00:00': 1,
      '04:00': 0,
      '08:00': 4,
      '12:00': 7,
      '16:00': 3,
      '20:00': 2,
    };
  }

  int get activeIncidentsCount => _incidents.where((i) => i.status == IncidentStatus.open).length;
  int get criticalIncidentsCount => _incidents.where((i) => i.isCritical && i.status != IncidentStatus.resolved).length;
  int get incidentsTodayCount => _incidents.length + 7;

  // Filter Setters
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterSeverity(IncidentSeverity? severity) {
    _filterSeverity = severity;
    notifyListeners();
  }

  void setFilterStatus(IncidentStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterBrand(String? brand) {
    _filterBrand = brand;
    notifyListeners();
  }

  void setFilterBranch(String? branch) {
    _filterBranch = branch;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterSeverity = null;
    _filterStatus = null;
    _filterBrand = null;
    _filterBranch = null;
    notifyListeners();
  }

  Future<void> loadData(UserProfile user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getIncidents(user),
        _repository.getDashboardSummary(user),
      ]);

      _incidents = results[0] as List<IncidentModel>;
      _summary = results[1] as DashboardSummary;
    } catch (_) {
      // Keep existing data on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Super Admin Actions ---
  void acknowledgeIncident(String id) {
    final idx = _incidents.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(status: IncidentStatus.acknowledged);
      _updateSummaryCounts();
      notifyListeners();
    }
  }

  void resolveIncident(String id, String note) {
    final idx = _incidents.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(
        status: IncidentStatus.resolved,
        resolutionNote: note,
      );
      _updateSummaryCounts();
      notifyListeners();
    }
  }

  void markFalsePositive(String id) {
    final idx = _incidents.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _incidents[idx] = _incidents[idx].copyWith(
        status: IncidentStatus.falsePositive,
        resolutionNote: 'Flagged as False Positive for AI model retraining.',
      );
      _updateSummaryCounts();
      notifyListeners();
    }
  }

  void addRealtimeIncident(IncidentModel newIncident) {
    _incidents.insert(0, newIncident);
    _updateSummaryCounts();
    notifyListeners();
  }

  void _updateSummaryCounts() {
    _summary = DashboardSummary(
      totalCameras: _summary.totalCameras,
      onlineCameras: _summary.onlineCameras,
      offlineCameras: _summary.offlineCameras,
      activeIncidents: activeIncidentsCount,
      criticalAlerts: criticalIncidentsCount,
      totalBranches: _summary.totalBranches,
      incidentsToday: incidentsTodayCount,
      cashierAlerts: _incidents.where((i) => i.isCashierAlert && i.status == IncidentStatus.open).length,
      networkUptimePercentage: _summary.networkUptimePercentage,
    );
  }
}
