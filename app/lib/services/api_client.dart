import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central API client for all backend communication
class ApiClient {
  late final Dio _dio;
  Dio get dio => _dio;
  static int _correlationNonce = 0;

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  // Production Cloud Run URL — can be overridden via --dart-define=BACKEND_URL=...
  static const String _defaultBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://mimz-backend-glaimgrznq-ew.a.run.app',
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

  /// Generate a lightweight correlation id for request tracing.
  String newCorrelationId({String prefix = 'corr'}) {
    _correlationNonce = (_correlationNonce + 1) % 1000000;
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$_correlationNonce';
  }

  // ─── Auth ──────────────────────────────────────────────
  Future<Map<String, dynamic>> bootstrap() async {
    // Send {} so servers that require a JSON body don't return 400.
    final correlationId = newCorrelationId(prefix: 'boot');
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/bootstrap',
      data: <String, dynamic>{},
      options: Options(
        headers: {'X-Correlation-Id': correlationId},
      ),
    );
    return res.data!;
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

  Future<Map<String, dynamic>> getGameState() async {
    final res = await _dio.get('/game-state');
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

  Future<Map<String, dynamic>> reclaimFrontier() async {
    final res = await _dio.post('/district/reclaim-frontier');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDistrictZones() async {
    final res = await _dio.get('/district/zones');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDistrictConflicts() async {
    final res = await _dio.get('/district/conflicts');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resolveConflict(String conflictId, {String? winnerId, int cellsWon = 1}) async {
    final res = await _dio.post('/district/conflicts/$conflictId/resolve', data: {
      if (winnerId != null) 'winnerId': winnerId,
      'cellsWon': cellsWon,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startRound({
    String mode = 'quiz',
    String? topic,
    String? difficulty,
    String? eventId,
  }) async {
    final res = await _dio.post('/rounds/start', data: {
      'mode': mode,
      if (topic != null) 'topic': topic,
      if (difficulty != null) 'difficulty': difficulty,
      if (eventId != null) 'eventId': eventId,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitRoundAnswer(
    String roundId, {
    required String answer,
    String? questionId,
  }) async {
    final res = await _dio.post('/rounds/$roundId/answer', data: {
      'answer': answer,
      if (questionId != null) 'questionId': questionId,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestRoundHint(String roundId) async {
    final res = await _dio.post('/rounds/$roundId/hint');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestRoundRepeat(String roundId) async {
    final res = await _dio.post('/rounds/$roundId/repeat');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> finishRound(String roundId) async {
    final res = await _dio.post('/rounds/$roundId/finish');
    return res.data as Map<String, dynamic>;
  }

  // ─── Squads ────────────────────────────────────────────
  Future<Map<String, dynamic>> createSquad(String name, {String? displayName}) async {
    final res = await _dio.post('/squad', data: {
      'name': name,
      if (displayName != null) 'displayName': displayName,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinSquad(String joinCode, {String? displayName}) async {
    final res = await _dio.post('/squad/join', data: {
      'joinCode': joinCode,
      if (displayName != null) 'displayName': displayName,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getMySquad() async {
    try {
      final res = await _dio.get('/squad/me');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSquad(String squadId) async {
    final res = await _dio.get('/squad/$squadId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSquadMembers(String squadId) async {
    final res = await _dio.get('/squad/$squadId/members');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSquadMissions(String squadId) async {
    final res = await _dio.get('/squad/$squadId/missions');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSquadMission(
    String squadId, {
    required String title,
    String? description,
    int goalProgress = 100,
    String? deadline,
  }) async {
    final res = await _dio.post('/squad/$squadId/missions', data: {
      'title': title,
      if (description != null) 'description': description,
      'goalProgress': goalProgress,
      if (deadline != null) 'deadline': deadline,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> contributeToMission(
    String squadId, {
    required String missionId,
    required int amount,
  }) async {
    final res = await _dio.post('/squad/$squadId/contribute', data: {
      'missionId': missionId,
      'amount': amount,
    });
    return res.data as Map<String, dynamic>;
  }

  // ─── Events ────────────────────────────────────────────
  Future<Map<String, dynamic>> getEvents() async {
    final res = await _dio.get('/events');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getEventZones() async {
    final res = await _dio.get('/events/zones');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinEvent(String eventId) async {
    final res = await _dio.post('/events/$eventId/join');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> participateInEvent(String eventId) async {
    final res = await _dio.post('/events/$eventId/participate');
    return res.data as Map<String, dynamic>;
  }

  // ─── Leaderboard ───────────────────────────────────────
  Future<Map<String, dynamic>> getLeaderboard({
    String? scope,
    String? topic,
    String? region,
    String? event,
  }) async {
    final path = scope != null ? '/leaderboards/$scope' : '/leaderboards';
    final res = await _dio.get(path, queryParameters: {
      if (scope != null) 'scope': scope,
      if (topic != null) 'topic': topic,
      if (region != null) 'region': region,
      if (event != null) 'event': event,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getEventLeaderboard(
      String eventId) async {
    final res = await _dio.get('/leaderboards/event', queryParameters: {'event': eventId});
    final data = res.data as Map<String, dynamic>;
    final entries = data['entries'] as List<dynamic>? ?? [];
    return entries.cast<Map<String, dynamic>>();
  }

  // ─── Rewards ───────────────────────────────────────────
  Future<Map<String, dynamic>> getRewards() async {
    final res = await _dio.get('/rewards');
    return res.data as Map<String, dynamic>;
  }

  // ─── Vision Quest History ───────────────────────────────
  Future<List<Map<String, dynamic>>> getVisionQuestHistory() async {
    final res = await _dio.get('/live/vision-quests');
    final data = res.data as Map<String, dynamic>;
    final quests = data['quests'] as List<dynamic>? ?? [];
    return quests.cast<Map<String, dynamic>>();
  }

  // ─── Missions ──────────────────────────────────────────
  Future<Map<String, dynamic>> getCurrentMission() async {
    final res = await _dio.get('/missions/current');
    return res.data as Map<String, dynamic>;
  }

  // ─── Health ────────────────────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get('/health');
      return res.statusCode == 200;
    } on DioException catch (e) {
      // Cloud Run can be reachable but IAM-protected (401/403). Treat this as
      // backend reachable to avoid false "backend unavailable" banners.
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Badges / Achievements ──────────────────────────────
  Future<Map<String, dynamic>> getBadges() async {
    final res = await _dio.get('/profile/badges');
    return res.data as Map<String, dynamic>;
  }

  // ─── Player Search ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    final res = await _dio.get('/profile/search', queryParameters: {'q': query});
    final results = res.data['results'] as List?;
    return results?.cast<Map<String, dynamic>>() ?? [];
  }
}

/// Interceptor that attaches Firebase ID token to every request,
/// and retries once on 401 using the parent [Dio] instance (which
/// preserves the base URL, timeouts, and all other interceptors).
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  static const _retriedFlag = 'auth_retried_once';

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _readValidToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
      if (alreadyRetried) {
        handler.next(err);
        return;
      }

      // Token may have expired mid-session — retry once using the parent Dio
      // (which preserves base URL so the request reaches the correct server).
      try {
        final newToken = await _readValidToken(forceRefresh: true);
        if (newToken != null) {
          final retryOptions = Options(
            method: err.requestOptions.method,
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newToken',
            },
            extra: {
              ...err.requestOptions.extra,
              _retriedFlag: true,
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

  Future<String?> _readValidToken({bool forceRefresh = false}) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken(forceRefresh);
        if (token != null) {
          await _storage.write(key: 'firebase_id_token', value: token);
          final expiry = DateTime.now().millisecondsSinceEpoch + 3600000;
          await _storage.write(key: 'firebase_id_token_expiry', value: expiry.toString());
          return token;
        }
      } catch (_) {
        // Fall back to storage token when Firebase refresh is temporarily unavailable.
      }
    }
    return _storage.read(key: 'firebase_id_token');
  }
}
