import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central API client for all backend communication
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // TODO: Update with your deployed Cloud Run URL
  static const String _defaultBaseUrl = 'http://localhost:8080';

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
    final res = await _dio.put('/profile', data: updates);
    return res.data as Map<String, dynamic>;
  }

  // ─── District ──────────────────────────────────────────
  Future<Map<String, dynamic>> getDistrict() async {
    final res = await _dio.get('/district');
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
    final res = await _dio.post('/squad/create', data: {'name': name});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinSquad(String squadId) async {
    final res = await _dio.post('/squad/join', data: {'squadId': squadId});
    return res.data as Map<String, dynamic>;
  }

  // ─── Events ────────────────────────────────────────────
  Future<Map<String, dynamic>> getEvents() async {
    final res = await _dio.get('/events');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinEvent(String eventId) async {
    final res = await _dio.post('/events/join', data: {'eventId': eventId});
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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: Trigger re-authentication flow
    }
    handler.next(err);
  }
}
