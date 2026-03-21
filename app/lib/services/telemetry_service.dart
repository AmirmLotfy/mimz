import 'package:flutter/foundation.dart';
import 'api_client.dart';

class TelemetryService {
  TelemetryService(this._apiClient);

  final ApiClient _apiClient;
  final Set<String> _dedupeKeys = <String>{};
  final String _sessionId = 'mobile_${DateTime.now().millisecondsSinceEpoch}';

  static DateTime? _appLaunchStartedAt;

  static void markAppLaunchStarted() {
    _appLaunchStartedAt ??= DateTime.now();
  }

  static int? get appLaunchElapsedMs {
    final startedAt = _appLaunchStartedAt;
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  Future<void> track(
    String event, {
    Map<String, dynamic>? metadata,
    String? route,
    String? correlationId,
    String? dedupeKey,
  }) async {
    if (dedupeKey != null && !_dedupeKeys.add(dedupeKey)) {
      return;
    }

    final payload = <String, dynamic>{
      'sessionId': _sessionId,
      'event': event,
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
      if (route != null) 'route': route,
      if (correlationId != null) 'correlationId': correlationId,
      'metadata': <String, dynamic>{
        'platform': _platformLabel,
        'buildMode': _buildModeLabel,
        if (appLaunchElapsedMs != null) 'appLaunchElapsedMs': appLaunchElapsedMs,
        ...?metadata,
      },
    };

    try {
      await _apiClient.post('/telemetry/client', payload);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Mimz][Telemetry] track failed for $event: $error');
      }
    }
  }

  String get _platformLabel {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String get _buildModeLabel {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }
}
