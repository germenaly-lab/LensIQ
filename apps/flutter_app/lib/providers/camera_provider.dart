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

  // Health section filters
  String? _healthBrandFilter;
  String? _healthBranchFilter;
  CameraStatus? _healthStatusFilter;

  CameraProvider(this._repository);

  List<CameraModel> get allCameras => _cameras;

  List<CameraModel> get cameras {
    if (_filterSource == null) return _cameras;
    return _cameras.where((c) => c.sourceType == _filterSource).toList();
  }

  // Filtered cameras for Camera Health section
  List<CameraModel> get healthFilteredCameras {
    return _cameras.where((cam) {
      if (_healthBrandFilter != null) {
        final bName = cam.brandName ?? '';
        if (!bName.toLowerCase().contains(_healthBrandFilter!.toLowerCase())) {
          return false;
        }
      }
      if (_healthBranchFilter != null) {
        final brName = cam.branchName ?? '';
        if (!brName.toLowerCase().contains(_healthBranchFilter!.toLowerCase())) {
          return false;
        }
      }
      if (_healthStatusFilter != null && cam.status != _healthStatusFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  CameraSourceType? get filterSource => _filterSource;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSessionModel? get activeSession => _activeSession;
  bool get isStreamingLoading => _isStreamingLoading;

  String? get healthBrandFilter => _healthBrandFilter;
  String? get healthBranchFilter => _healthBranchFilter;
  CameraStatus? get healthStatusFilter => _healthStatusFilter;

  int get totalCamerasCount => _cameras.length;
  int get rtspCamerasCount => _cameras.where((c) => c.isRtsp).length;
  int get hikvisionCamerasCount => _cameras.where((c) => c.isHikvision).length;

  int get onlineCount => _cameras.where((c) => c.status == CameraStatus.online).length;
  int get offlineCount => _cameras.where((c) => c.status == CameraStatus.offline).length;
  int get warningCount => _cameras.where((c) => c.status == CameraStatus.warning).length;
  int get unknownCount => _cameras.where((c) => c.status == CameraStatus.unknown).length;

  double get availabilityPercentage {
    if (_cameras.isEmpty) return 100.0;
    return double.parse(((onlineCount / _cameras.length) * 100).toStringAsFixed(1));
  }

  void setFilterSource(CameraSourceType? type) {
    _filterSource = type;
    notifyListeners();
  }

  void setHealthBrandFilter(String? brand) {
    _healthBrandFilter = brand;
    notifyListeners();
  }

  void setHealthBranchFilter(String? branch) {
    _healthBranchFilter = branch;
    notifyListeners();
  }

  void setHealthStatusFilter(CameraStatus? status) {
    _healthStatusFilter = status;
    notifyListeners();
  }

  void clearHealthFilters() {
    _healthBrandFilter = null;
    _healthBranchFilter = null;
    _healthStatusFilter = null;
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

  Future<void> addCamera(UserProfile user, CameraModel newCam) async {
    _cameras.insert(0, newCam);
    notifyListeners();

    try {
      final persisted = await _repository.createCamera(user, newCam);
      if (persisted != null) {
        final index = _cameras.indexWhere((c) => c.id == newCam.id);
        if (index != -1) {
          _cameras[index] = persisted;
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'Warning: Camera saved locally ($e)';
      notifyListeners();
    }
  }

  void updateCamera(CameraModel updated) {
    final idx = _cameras.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _cameras[idx] = updated;
      notifyListeners();
    }
  }

  void toggleCameraEnabled(String cameraId) {
    final idx = _cameras.indexWhere((c) => c.id == cameraId);
    if (idx != -1) {
      _cameras[idx] = _cameras[idx].copyWith(enabled: !_cameras[idx].enabled);
      notifyListeners();
    }
  }
}
