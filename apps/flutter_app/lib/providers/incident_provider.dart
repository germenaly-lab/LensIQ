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

  IncidentProvider(this._repository);

  List<IncidentModel> get incidents => _incidents;
  DashboardSummary get summary => _summary;
  bool get isLoading => _isLoading;

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
}
