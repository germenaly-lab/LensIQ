import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/user_profile.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}

class ApiClient {
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Map<String, String> _buildHeaders({UserProfile? user, String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (user != null) {
      headers['x-user-id'] = user.id;
      headers['x-user-role'] = user.role == UserRole.superAdmin
          ? 'super_admin'
          : user.role == UserRole.brandManager
              ? 'brand_manager'
              : 'branch_security';
      if (user.companyId != null) {
        headers['x-company-id'] = user.companyId!;
      }
      if (user.brandId != null) {
        headers['x-brand-id'] = user.brandId!;
      }
      if (user.branchId != null) {
        headers['x-branch-id'] = user.branchId!;
      }
      if (user.authorizedBranchIds.isNotEmpty) {
        headers['x-authorized-branches'] = user.authorizedBranchIds.join(',');
      }
    }

    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    UserProfile? user,
    String? token,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(user: user, token: token))
          .timeout(const Duration(seconds: 4));

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Network connection failed: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    UserProfile? user,
    String? token,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(user: user, token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Network connection failed: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    UserProfile? user,
    String? token,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
      final response = await _httpClient
          .put(
            uri,
            headers: _buildHeaders(user: user, token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Network connection failed: $e',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    UserProfile? user,
    String? token,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.backendBaseUrl}$path');
      final response = await _httpClient
          .patch(
            uri,
            headers: _buildHeaders(user: user, token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Network connection failed: $e',
        statusCode: 0,
      );
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response, T Function(dynamic json)? fromJson) {
    try {
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = decoded['data'] ?? decoded;
        final data = fromJson != null ? fromJson(payload) : payload as T;
        return ApiResponse<T>(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        final errorMsg = decoded['error'] ?? decoded['message'] ?? 'Request failed (${response.statusCode})';
        return ApiResponse<T>(
          success: false,
          error: errorMsg.toString(),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }
}
