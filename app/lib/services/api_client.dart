import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central API client for all backend communication
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // TODO: Update with your deployed Cloud Run URL
  static const String _defaultBaseUrl = 'https://mimz-backend-1012962167727.us-central1.run.app';

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

    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
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

  /// Generic PATCH method for arbitrary routes (e.g. /profile with emblemId or districtName)
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) async {
    final res = await _dio.patch(path, data: data);
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
      final res = await _dio.get('/healthz');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Interceptor that attaches Firebase ID token to every request
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._storage);

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
      // Token expired — attempt to refresh and retry once
      try {
        final newToken = await _storage.read(key: 'firebase_id_token');
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          // Retry the request with the refreshed token
          final dio = Dio();
          final response = await dio.request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            ),
            data: err.requestOptions.data,
          );
          return handler.resolve(response);
        }
      } catch (_) {
        // Retry failed — fall through to error
      }
    }
    handler.next(err);
  }
}
