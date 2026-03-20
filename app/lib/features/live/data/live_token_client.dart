import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    String? correlationId,
    String? eventId,
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
      final response = await _dio.post(
        '/live/ephemeral-token',
        data: {
          'sessionType': sessionType,
          if (eventId != null) 'eventId': eventId,
        },
        options: Options(
          headers: {
            if (correlationId != null) 'X-Correlation-Id': correlationId,
          },
        ),
      );

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
      if (kDebugMode) {
        final traceId = response.headers.value('x-correlation-id');
        debugPrint('[Mimz][Live] token_fetched sessionType=$sessionType traceId=$traceId');
      }
      return token;
    } on DioException catch (e) {
      final traceId = e.response?.headers.value('x-correlation-id');
      if (kDebugMode) {
        final statusCode = e.response?.statusCode;
        final code = e.response?.data is Map ? (e.response?.data as Map)['code'] : null;
        debugPrint('[Mimz][Live] token_fetch_failed statusCode=$statusCode code=$code traceId=$traceId');
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw const LiveError(
          code: LiveErrorCode.tokenFetchFailed,
          message: 'Sign in again to use Live.',
          recovery: LiveErrorRecovery.fatal,
        );
      }
      if (statusCode == 403) {
        throw const LiveError(
          code: LiveErrorCode.tokenFetchFailed,
          message: 'Access restricted. Try again later.',
          recovery: LiveErrorRecovery.fatal,
        );
      }
      if (statusCode == 429) {
        throw const LiveError(
          code: LiveErrorCode.rateLimited,
          message: 'Too many requests — try again later',
          recovery: LiveErrorRecovery.retry,
        );
      }
      if (statusCode == 503) {
        final body = e.response?.data;
        final msg = body is Map && body['error'] is String
            ? body['error'] as String
            : 'Live sessions are temporarily unavailable. Try again later.';
        throw LiveError(
          code: LiveErrorCode.tokenFetchFailed,
          message: msg,
          detail: body is Map ? body['code'] as String? : null,
          recovery: LiveErrorRecovery.fatal,
        );
      }
      if (statusCode != null && statusCode >= 500) {
        throw LiveError(
          code: LiveErrorCode.tokenFetchFailed,
          message: 'Server error. Try again in a moment.',
          detail: 'status=$statusCode; traceId=$traceId',
          recovery: LiveErrorRecovery.retry,
        );
      }
      final isConnectionError = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      throw LiveError(
        code: LiveErrorCode.tokenFetchFailed,
        message: isConnectionError
            ? 'Could not reach the server. Check your connection and retry.'
            : 'Failed to fetch session token.',
        detail: 'status=$statusCode; traceId=$traceId; ${e.message}',
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
