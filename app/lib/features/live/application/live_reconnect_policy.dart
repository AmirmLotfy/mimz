import 'dart:math';

/// Reconnect strategy with exponential backoff + jitter.
///
/// Prevents thundering herd and gives the server breathing room.
class LiveReconnectPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  int _attempts = 0;
  final _random = Random();

  LiveReconnectPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Whether another reconnect attempt is allowed.
  bool get canRetry => _attempts < maxAttempts;

  /// Current attempt number (0-based).
  int get attempts => _attempts;

  /// Calculate the delay before the next reconnect attempt.
  /// Uses exponential backoff with jitter.
  Duration get nextDelay {
    if (!canRetry) return Duration.zero;

    final baseMs = initialDelay.inMilliseconds *
        pow(backoffMultiplier, _attempts).toInt();
    final cappedMs = min(baseMs, maxDelay.inMilliseconds);

    // Add ±25% jitter
    final jitter = (cappedMs * 0.25 * (2 * _random.nextDouble() - 1)).round();
    final totalMs = max(100, cappedMs + jitter);

    return Duration(milliseconds: totalMs);
  }

  /// Record a reconnect attempt.
  void recordAttempt() {
    _attempts++;
  }

  /// Reset after successful reconnect.
  void reset() {
    _attempts = 0;
  }

  /// Whether a fresh token should be fetched before reconnecting.
  /// Always true after the first attempt (token may have expired).
  bool get shouldRefreshToken => _attempts >= 1;

  @override
  String toString() => 'ReconnectPolicy(attempt: $_attempts/$maxAttempts, '
      'nextDelay: ${nextDelay.inMilliseconds}ms)';
}
