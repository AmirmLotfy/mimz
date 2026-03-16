import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central API client for all backend communication
class ApiClient {
  late final Dio _dio;
  Dio get dio => _dio;

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  // Production Cloud Run URL — can be overridden via --dart-define=BACKEND_URL=...
  static const String _defaultBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://mimz-backend-1012962167727.europe-west1.run.app',
  );

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Pass the _dio reference so the retry interceptor preserves base URL + settings
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  // ─── Auth ──────────────────────────────────────────────
  Future<Map<String, dynamic>> bootstrap() async {
    final res = await _dio.post('/auth/bootstrap');
    return res.data as Map<String, dynamic>;
  }

  // ─── Live ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getEphemeralToken() async {
    final res = await _dio.post('/live/ephemeral-token');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> executeToolCall({
    required String toolName,
    required Map<String, dynamic> args,
    required String sessionId,
  }) async {
    final res = await _dio.post('/live/tool-execute', data: {
      'toolName': toolName,
      'args': args,
      'sessionId': sessionId,
    });
    return res.data as Map<String, dynamic>;
  }

  // ─── Profile ───────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/profile');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    final res = await _dio.patch('/profile', data: updates);
    return res.data as Map<String, dynamic>;
  }

  /// Generic PATCH method for arbitrary routes
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) async {
    final res = await _dio.patch(path, data: data);
    return res.data as Map<String, dynamic>;
  }

  /// Generic POST method for arbitrary routes
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final res = await _dio.post(path, data: data);
    return res.data as Map<String, dynamic>;
  }

  /// Generic GET method for arbitrary routes
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get(path, queryParameters: query);
    return res.data as Map<String, dynamic>;
  }

  // ─── District ──────────────────────────────────────────
  Future<Map<String, dynamic>> getDistrict() async {
    final res = await _dio.get('/district');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> expandTerritory(int sectors) async {
    final res = await _dio.post('/district/expand', data: {
      'sectors': sectors,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addResources(Map<String, dynamic> resources) async {
    final res = await _dio.post('/district/resources', data: resources);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlockStructure(String structureId) async {
    final res = await _dio.post('/district/unlock-structure', data: {
      'structureId': structureId,
    });
    return res.data as Map<String, dynamic>;
  }

  // ─── Squads ────────────────────────────────────────────
  Future<Map<String, dynamic>> createSquad(String name) async {
    final res = await _dio.post('/squad', data: {'name': name});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinSquad(String joinCode) async {
    final res = await _dio.post('/squad/join', data: {'joinCode': joinCode});
    return res.data as Map<String, dynamic>;
  }

  // ─── Events ────────────────────────────────────────────
  Future<Map<String, dynamic>> getEvents() async {
    final res = await _dio.get('/events');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinEvent(String eventId) async {
    final res = await _dio.post('/events/$eventId/join');
    return res.data as Map<String, dynamic>;
  }

  // ─── Leaderboard ───────────────────────────────────────
  Future<Map<String, dynamic>> getLeaderboard() async {
    final res = await _dio.get('/leaderboard');
    return res.data as Map<String, dynamic>;
  }

  // ─── Rewards ───────────────────────────────────────────
  Future<Map<String, dynamic>> getRewards() async {
    final res = await _dio.get('/rewards');
    return res.data as Map<String, dynamic>;
  }

  // ─── Health ────────────────────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get('/health');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Interceptor that attaches Firebase ID token to every request,
/// and retries once on 401 using the parent [Dio] instance (which
/// preserves the base URL, timeouts, and all other interceptors).
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'firebase_id_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token may have expired mid-session — retry once using the parent Dio
      // (which preserves base URL so the request reaches the correct server).
      try {
        final newToken = await _storage.read(key: 'firebase_id_token');
        if (newToken != null) {
          final retryOptions = Options(
            method: err.requestOptions.method,
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newToken',
            },
          );
          final response = await _dio.request<dynamic>(
            err.requestOptions.path,
            options: retryOptions,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
          );
          return handler.resolve(response);
        }
      } catch (_) {
        // Retry failed — fall through to original error
      }
    }
    handler.next(err);
  }
}
