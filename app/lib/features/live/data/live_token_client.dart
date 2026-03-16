import 'package:dio/dio.dart';
import '../domain/live_event.dart';
import 'live_backend_dtos.dart';

/// Fetches and validates ephemeral tokens from the backend.
///
/// Handles retry on expiry and keeps token lifetime concerns isolated.
/// Each session type (onboarding, quiz, vision_quest) gets its own cached
/// token so system instructions are never cross-contaminated.
class LiveTokenClient {
  final Dio _dio;
  EphemeralTokenResponse? _cachedToken;
  String? _cachedSessionType;

  LiveTokenClient({required Dio dio}) : _dio = dio;

  /// Fetch a fresh ephemeral token. If a valid cached token exists for the
  /// same [sessionType] with at least [minRemaining] time left, returns it.
  Future<EphemeralTokenResponse> fetchToken({
    required String sessionType,
    Duration minRemaining = const Duration(minutes: 1),
  }) async {
    // Return cached only if same session type and still valid
    if (_cachedToken != null &&
        _cachedSessionType == sessionType &&
        !_cachedToken!.isExpired &&
        _cachedToken!.timeRemaining > minRemaining) {
      return _cachedToken!;
    }

    try {
      final response = await _dio.post('/live/ephemeral-token', data: {
        'sessionType': sessionType,
      });

      final token = EphemeralTokenResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (token.isExpired) {
        throw const LiveError(
          code: LiveErrorCode.tokenExpired,
          message: 'Server returned an already-expired token',
          recovery: LiveErrorRecovery.retry,
        );
      }

      _cachedToken = token;
      _cachedSessionType = sessionType;
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const LiveError(
          code: LiveErrorCode.tokenFetchFailed,
          message: 'Authentication required',
          recovery: LiveErrorRecovery.fatal,
        );
      }
      if (e.response?.statusCode == 429) {
        throw const LiveError(
          code: LiveErrorCode.rateLimited,
          message: 'Too many requests — try again later',
          recovery: LiveErrorRecovery.retry,
        );
      }
      throw LiveError(
        code: LiveErrorCode.tokenFetchFailed,
        message: 'Failed to fetch session token',
        detail: e.message,
        recovery: LiveErrorRecovery.retry,
      );
    }
  }

  /// Invalidate the cached token (e.g., before reconnect).
  void invalidate() {
    _cachedToken = null;
  }

  /// Whether a usable token is available.
  bool get hasValidToken => _cachedToken != null && !_cachedToken!.isExpired;
}
