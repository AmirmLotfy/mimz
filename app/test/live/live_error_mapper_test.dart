import 'package:flutter_test/flutter_test.dart';
import 'package:mimz/features/live/application/live_error_mapper.dart';
import 'package:mimz/features/live/domain/live_event.dart';

void main() {
  group('LiveErrorMapper', () {
    test('maps all error codes to non-empty user messages', () {
      for (final code in LiveErrorCode.values) {
        final error = LiveError(
          code: code,
          message: 'test',
          recovery: LiveErrorRecovery.retry,
        );
        final message = LiveErrorMapper.userMessage(error);
        expect(message.isNotEmpty, isTrue, reason: 'Missing message for $code');
      }
    });

    test('fatal errors have blocking severity', () {
      const error = LiveError(
        code: LiveErrorCode.permissionDenied,
        message: 'denied',
        recovery: LiveErrorRecovery.fatal,
      );
      expect(LiveErrorMapper.severity(error), ErrorSeverity.blocking);
    });

    test('retry errors have transient severity', () {
      const error = LiveError(
        code: LiveErrorCode.toolExecutionFailed,
        message: 'failed',
        recovery: LiveErrorRecovery.retry,
      );
      expect(LiveErrorMapper.severity(error), ErrorSeverity.transient);
    });

    test('reconnect errors have banner severity', () {
      const error = LiveError(
        code: LiveErrorCode.wsUnexpectedClose,
        message: 'closed',
        recovery: LiveErrorRecovery.reconnect,
      );
      expect(LiveErrorMapper.severity(error), ErrorSeverity.banner);
    });

    test('logPayload includes all required fields', () {
      const error = LiveError(
        code: LiveErrorCode.tokenExpired,
        message: 'expired',
        detail: 'TTL exceeded',
        recovery: LiveErrorRecovery.refreshToken,
      );
      final payload = LiveErrorMapper.logPayload(error);

      expect(payload['code'], 'tokenExpired');
      expect(payload['message'], 'expired');
      expect(payload['detail'], 'TTL exceeded');
      expect(payload['recovery'], 'refreshToken');
      expect(payload.containsKey('timestamp'), isTrue);
    });
  });
}
