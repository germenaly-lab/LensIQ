import '../models/incident.dart';
import '../models/user_profile.dart';
import '../models/dashboard_summary.dart';
import '../services/mock_data_service.dart';

class IncidentRepository {
  /**
   * Retrieves AI detection incidents filtered by tenant authorization
   */
  Future<List<IncidentModel>> getIncidents(UserProfile user) async {
    // In current phase, AI events are retrieved from database/mock service
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDataService.getIncidentsForUser(user);
  }

  Future<DashboardSummary> getDashboardSummary(UserProfile user) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return MockDataService.getSummaryForUser(user);
  }
}
