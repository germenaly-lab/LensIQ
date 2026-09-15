import '../core/network/api_client.dart';
import '../models/camera.dart';
import '../models/user_profile.dart';
import '../models/stream_session.dart';
import '../services/mock_data_service.dart';

class CameraRepository {
  final ApiClient _apiClient;

  CameraRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /**
   * Retrieves cameras authorized for the current user.
   * Tries backend API first; falls back seamlessly to demo dataset if backend is offline.
   */
  Future<List<CameraModel>> getCameras(UserProfile user) async {
    final response = await _apiClient.get(
      '/cameras',
      user: user,
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => CameraModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <CameraModel>[];
      },
    );

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      return response.data!;
    }

    // Offline / Demo Fallback
    return MockDataService.getCamerasForUser(user);
  }

  /**
   * Initiates a live streaming session via Phase 4 Streaming Gateway
   */
  Future<StreamSessionModel> startStreamSession(
    UserProfile user,
    String cameraId, {
    CameraSourceType? sourceType,
    String streamProfile = 'main',
    String protocol = 'webrtc',
    bool demoMode = true,
  }) async {
    final response = await _apiClient.post(
      '/streams/$cameraId/session',
      user: user,
      body: {
        'streamProfile': streamProfile,
        'protocol': protocol,
        'demoMode': demoMode,
      },
      fromJson: (json) => StreamSessionModel.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    // Offline / Demo fallback: use passed sourceType or fallback to demoCameras lookup
    final effectiveType = sourceType ??
        MockDataService.demoCameras
            .firstWhere(
              (c) => c.id == cameraId,
              orElse: () => MockDataService.demoCameras.first,
            )
            .sourceType;

    return MockDataService.createMockStreamSession(cameraId, effectiveType);
  }

  /**
   * Provisions a new camera in the backend
   */
  Future<CameraModel?> createCamera(UserProfile user, CameraModel camera) async {
    final response = await _apiClient.post(
      '/cameras',
      user: user,
      body: camera.toJson(),
      fromJson: (json) => CameraModel.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    // Return the camera optimistically for offline/demo operation
    return camera;
  }

  /**
   * Releases a live stream session when the user leaves or camera is hidden
   */
  Future<bool> stopStreamSession(UserProfile user, String cameraId, String sessionId) async {
    final response = await _apiClient.post(
      '/streams/$cameraId/stop',
      user: user,
      body: {'sessionId': sessionId},
    );
    return response.success;
  }

  /**
   * Triggers an explicit stream reconnection cycle
   */
  Future<bool> reconnectStreamSession(UserProfile user, String cameraId) async {
    final response = await _apiClient.post(
      '/streams/$cameraId/reconnect',
      user: user,
    );
    return response.success;
  }
}
