import 'package:flutter_test/flutter_test.dart';
import 'package:mimz_app/features/live/data/live_message_codec.dart';
import 'package:mimz_app/features/live/domain/live_event.dart';

void main() {
  group('LiveMessageCodec.decode', () {
    final codec = LiveMessageCodec();

    test('maps server config/auth error to fatal SessionError', () {
      final events = codec.decode('{"error":{"code":403,"message":"Permission denied"}}');
      expect(events, hasLength(1));
      final event = events.first as SessionError;
      expect(event.error.recovery, LiveErrorRecovery.fatal);
      expect(event.error.code, LiveErrorCode.permissionDenied);
    });

    test('maps goAway to fatal sessionExpired error', () {
      final events = codec.decode('{"goAway":{"timeLeft":"5s"}}');
      expect(events, hasLength(1));
      final event = events.first as SessionError;
      expect(event.error.code, LiveErrorCode.sessionExpired);
      expect(event.error.recovery, LiveErrorRecovery.fatal);
    });

    test('maps malformed payload to wsMalformedMessage retry', () {
      final events = codec.decode('{not-json}');
      expect(events, hasLength(1));
      final event = events.first as SessionError;
      expect(event.error.code, LiveErrorCode.wsMalformedMessage);
      expect(event.error.recovery, LiveErrorRecovery.retry);
    });
  });
}
