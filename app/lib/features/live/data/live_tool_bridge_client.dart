import 'package:dio/dio.dart';
import '../domain/live_event.dart';
import '../domain/live_tool_registry.dart';
import 'live_backend_dtos.dart';

/// Bridges Gemini Live tool calls to backend execution.
///
/// Listens for [ToolCallRequested] events, routes them to the backend
/// `/live/tool-execute` endpoint, and returns structured results.
class LiveToolBridgeClient {
  final Dio _dio;

  LiveToolBridgeClient({required Dio dio}) : _dio = dio;

  /// Execute a tool call against the backend.
  ///
  /// Returns [ToolExecutionResponse] with backend-confirmed result.
  /// Throws [LiveError] on failure.
  Future<ToolExecutionResponse> execute(ToolCallRequested call, {
    required String sessionId,
    String? correlationId,
  }) async {
    // Validate tool name
    if (!LiveTools.isKnown(call.toolName)) {
      return ToolExecutionResponse(
        success: false,
        data: {'error': 'Unknown tool: ${call.toolName}'},
        error: 'Unrecognized tool name',
      );
    }

    final request = ToolExecutionRequest(
      toolName: call.toolName,
      arguments: call.arguments,
      sessionId: sessionId,
      correlationId: correlationId ?? 'corr_${DateTime.now().millisecondsSinceEpoch}',
    );

    try {
      final response = await _dio.post(
        '/live/tool-execute',
        data: request.toJson(),
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      return ToolExecutionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const LiveError(
          code: LiveErrorCode.backendTimeout,
          message: 'Tool execution timed out',
          recovery: LiveErrorRecovery.retry,
        );
      }
      throw LiveError(
        code: LiveErrorCode.toolExecutionFailed,
        message: 'Tool execution failed: ${call.toolName}',
        detail: e.message,
        recovery: LiveErrorRecovery.retry,
      );
    }
  }
}
