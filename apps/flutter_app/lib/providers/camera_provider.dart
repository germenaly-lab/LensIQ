import 'package:flutter/foundation.dart';
import '../models/camera.dart';
import '../models/user_profile.dart';
import '../models/stream_session.dart';
import '../repositories/camera_repository.dart';

class CameraProvider extends ChangeNotifier {
  final CameraRepository _repository;

  List<CameraModel> _cameras = [];
  CameraSourceType? _filterSource;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSessionModel? _activeSession;
  bool _isStreamingLoading = false;

  CameraProvider(this._repository);

  List<CameraModel> get cameras {
    if (_filterSource == null) return _cameras;
    return _cameras.where((c) => c.sourceType == _filterSource).toList();
  }

  CameraSourceType? get filterSource => _filterSource;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSessionModel? get activeSession => _activeSession;
  bool get isStreamingLoading => _isStreamingLoading;

  int get totalCamerasCount => _cameras.length;
  int get rtspCamerasCount => _cameras.where((c) => c.isRtsp).length;
  int get hikvisionCamerasCount => _cameras.where((c) => c.isHikvision).length;
  int get onlineCount => _cameras.where((c) => c.isOnline).length;

  void setFilterSource(CameraSourceType? type) {
    _filterSource = type;
    notifyListeners();
  }

  Future<void> loadCameras(UserProfile user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cameras = await _repository.getCameras(user);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startStream(UserProfile user, String cameraId) async {
    _isStreamingLoading = true;
    _activeSession = null;
    notifyListeners();

    try {
      _activeSession = await _repository.startStreamSession(
        user,
        cameraId,
        streamProfile: 'main',
        protocol: 'webrtc',
        demoMode: true,
      );
    } catch (e) {
      _errorMessage = 'Failed to start stream: $e';
    } finally {
      _isStreamingLoading = false;
      notifyListeners();
    }
  }

  void closeActiveStream() {
    _activeSession = null;
    notifyListeners();
  }
}
