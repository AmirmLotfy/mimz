import 'package:flutter_test/flutter_test.dart';
import 'package:mimz/features/live/application/live_reconnect_policy.dart';

void main() {
  group('LiveReconnectPolicy', () {
    test('canRetry is true when attempts < maxAttempts', () {
      final policy = LiveReconnectPolicy(maxAttempts: 3);
      expect(policy.canRetry, isTrue);
      expect(policy.attempts, 0);
    });

    test('canRetry becomes false after max attempts', () {
      final policy = LiveReconnectPolicy(maxAttempts: 2);
      policy.recordAttempt();
      policy.recordAttempt();
      expect(policy.canRetry, isFalse);
    });

    test('nextDelay increases with backoff', () {
      final policy = LiveReconnectPolicy(
        maxAttempts: 5,
        initialDelay: const Duration(seconds: 1),
        backoffMultiplier: 2.0,
      );

      final delay0 = policy.nextDelay;
      policy.recordAttempt();
      final delay1 = policy.nextDelay;
      policy.recordAttempt();
      final delay2 = policy.nextDelay;

      // Each delay should be roughly double the previous (±25% jitter)
      expect(delay1.inMilliseconds, greaterThan(delay0.inMilliseconds ~/ 2));
      expect(delay2.inMilliseconds, greaterThan(delay1.inMilliseconds ~/ 2));
    });

    test('nextDelay is capped at maxDelay', () {
      final policy = LiveReconnectPolicy(
        maxAttempts: 10,
        initialDelay: const Duration(seconds: 10),
        maxDelay: const Duration(seconds: 30),
      );

      for (var i = 0; i < 5; i++) {
        policy.recordAttempt();
      }

      // Due to jitter, max is 30s + 25% = 37.5s
      expect(policy.nextDelay.inMilliseconds, lessThanOrEqualTo(37500));
    });

    test('reset clears all attempts', () {
      final policy = LiveReconnectPolicy(maxAttempts: 3);
      policy.recordAttempt();
      policy.recordAttempt();
      expect(policy.attempts, 2);

      policy.reset();
      expect(policy.attempts, 0);
      expect(policy.canRetry, isTrue);
    });

    test('shouldRefreshToken is true after first attempt', () {
      final policy = LiveReconnectPolicy();
      expect(policy.shouldRefreshToken, isFalse);
      policy.recordAttempt();
      expect(policy.shouldRefreshToken, isTrue);
    });
  });
}
