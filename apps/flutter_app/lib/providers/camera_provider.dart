import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera.dart';
import '../models/user_profile.dart';
import '../models/stream_session.dart';
import '../repositories/camera_repository.dart';

enum LiveStreamState {
  connecting,
  online,
  offline,
  reconnecting,
  streamError,
  deviceUnavailable;

  String get displayName {
    switch (this) {
      case LiveStreamState.connecting:
        return 'Connecting';
      case LiveStreamState.online:
        return 'Online';
      case LiveStreamState.offline:
        return 'Offline';
      case LiveStreamState.reconnecting:
        return 'Reconnecting';
      case LiveStreamState.streamError:
        return 'Stream Error';
      case LiveStreamState.deviceUnavailable:
        return 'Device Unavailable';
    }
  }
}

class CameraProvider extends ChangeNotifier {
  final CameraRepository _repository;
  final SharedPreferences? _prefs;

  List<CameraModel> _cameras = [];
  CameraSourceType? _filterSource;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSessionModel? _activeSession;
  bool _isStreamingLoading = false;

  // Multi-session tracking for 1, 4, and 9 camera layouts
  final Map<String, StreamSessionModel> _activeSessions = {};
  final Map<String, LiveStreamState> _streamStates = {};
  int _gridLayout = 4; // 1, 4, or 9 cameras
  bool _demoSimulationMode = true;

  // Health section filters
  String? _healthBrandFilter;
  String? _healthBranchFilter;
  CameraStatus? _healthStatusFilter;

  CameraProvider(this._repository, [this._prefs]);

  List<CameraModel> get allCameras => _cameras;
  int get gridLayout => _gridLayout;
  bool get demoSimulationMode => _demoSimulationMode;

  Map<String, StreamSessionModel> get activeSessions => _activeSessions;

  void setGridLayout(int count) {
    if (count == 1 || count == 4 || count == 9) {
      _gridLayout = count;
      notifyListeners();
    }
  }

  void toggleDemoSimulation(bool val) {
    _demoSimulationMode = val;
    notifyListeners();
  }

  LiveStreamState getStreamState(String cameraId) {
    final camera = _cameras.firstWhere(
      (c) => c.id == cameraId,
      orElse: () => CameraModel(
        id: cameraId,
        name: 'Camera',
        companyId: '',
        brandId: '',
        branchId: '',
        sourceType: CameraSourceType.rtsp,
        status: CameraStatus.offline,
      ),
    );

    if (!camera.isOnline) {
      return LiveStreamState.offline;
    }

    return _streamStates[cameraId] ?? LiveStreamState.connecting;
  }

  StreamSessionModel? getActiveSessionForCamera(String cameraId) {
    return _activeSessions[cameraId] ?? (_activeSession?.cameraId == cameraId ? _activeSession : null);
  }

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
      if (_prefs != null && _prefs!.containsKey('lensiq_custom_cameras')) {
        try {
          final raw = _prefs!.getString('lensiq_custom_cameras')!;
          final customList = (jsonDecode(raw) as List)
              .map((c) => CameraModel.fromJson(c as Map<String, dynamic>))
              .toList();
          for (final cam in customList) {
            if (!_cameras.any((c) => c.id == cam.id)) {
              _cameras.insert(0, cam);
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startCameraStream(UserProfile user, String cameraId, {bool demoMode = true}) async {
    final knownCam = _cameras.where((c) => c.id == cameraId).firstOrNull;
    if (knownCam != null && !knownCam.isOnline) {
      _streamStates[cameraId] = LiveStreamState.offline;
      notifyListeners();
      return;
    }

    _streamStates[cameraId] = LiveStreamState.connecting;
    notifyListeners();

    try {
      final session = await _repository.startStreamSession(
        user,
        cameraId,
        sourceType: knownCam?.sourceType,
        streamProfile: 'main',
        protocol: 'webrtc',
        demoMode: demoMode,
      );
      _activeSessions[cameraId] = session;
      _streamStates[cameraId] = LiveStreamState.online;
      if (_activeSession == null || _activeSession!.cameraId == cameraId) {
        _activeSession = session;
      }
    } catch (e) {
      _streamStates[cameraId] = LiveStreamState.streamError;
      _errorMessage = 'Stream error for $cameraId: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> stopCameraStream(UserProfile user, String cameraId) async {
    final session = _activeSessions[cameraId];
    if (session != null) {
      try {
        await _repository.stopStreamSession(user, cameraId, session.sessionId);
      } catch (_) {}
      _activeSessions.remove(cameraId);
    }
    if (_activeSession?.cameraId == cameraId) {
      _activeSession = null;
    }
    _streamStates.remove(cameraId);
    notifyListeners();
  }

  Future<void> reconnectCameraStream(UserProfile user, String cameraId, {bool demoMode = true}) async {
    _streamStates[cameraId] = LiveStreamState.reconnecting;
    notifyListeners();
    try {
      await _repository.reconnectStreamSession(user, cameraId);
    } catch (_) {}
    await startCameraStream(user, cameraId, demoMode: demoMode);
  }

  void stopAllStreams(UserProfile user) {
    for (final entry in _activeSessions.entries) {
      try {
        _repository.stopStreamSession(user, entry.key, entry.value.sessionId);
      } catch (_) {}
    }
    _activeSessions.clear();
    _streamStates.clear();
    _activeSession = null;
    notifyListeners();
  }

  Future<void> startStream(UserProfile user, String cameraId) async {
    _isStreamingLoading = true;
    _activeSession = null;
    notifyListeners();

    try {
      await startCameraStream(user, cameraId, demoMode: _demoSimulationMode);
      _activeSession = _activeSessions[cameraId];
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
    if (_prefs != null) {
      try {
        final existingRaw = _prefs!.getString('lensiq_custom_cameras');
        List<dynamic> list = existingRaw != null ? jsonDecode(existingRaw) as List : [];
        list.insert(0, newCam.toJson());
        _prefs!.setString('lensiq_custom_cameras', jsonEncode(list));
      } catch (_) {}
    }
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
