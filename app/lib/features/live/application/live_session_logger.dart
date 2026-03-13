import 'package:flutter/foundation.dart';
import '../domain/live_event.dart';

/// Debug session logger that records an event timeline locally.
///
/// Disabled in release builds. Can optionally POST summaries to backend.
class LiveSessionLogger {
  final List<_LogEntry> _entries = [];
  final int maxEntries;

  LiveSessionLogger({this.maxEntries = 500});

  bool get isEnabled => kDebugMode;

  /// Log a session event.
  void log(String event, {Map<String, dynamic>? metadata}) {
    if (!isEnabled) return;

    _entries.add(_LogEntry(
      timestamp: DateTime.now(),
      event: event,
      metadata: metadata,
    ));

    // Prevent unbounded growth
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('[Mimz Live] $event${metadata != null ? ' $metadata' : ''}');
    }
  }

  /// Log a [LiveEvent].
  void logEvent(LiveEvent event) {
    switch (event) {
      case SessionStarted(sessionId: final id):
        log('session_started', metadata: {'sessionId': id});
      case SessionClosed(closeCode: final code):
        log('session_closed', metadata: {'closeCode': code});
      case ModelTurnStarted():
        log('model_turn_started');
      case ModelTurnEnded():
        log('model_turn_ended');
      case UserTurnStarted():
        log('user_turn_started');
      case UserTurnEnded():
        log('user_turn_ended');
      case TranscriptDelta(text: final t, isModel: final m):
        log('transcript_delta', metadata: {'isModel': m, 'length': t.length});
      case AudioChunkReceived(data: final d):
        log('audio_chunk', metadata: {'bytes': d.length});
      case ToolCallRequested(toolName: final n, callId: final id):
        log('tool_call_requested', metadata: {'tool': n, 'callId': id});
      case ToolCallCompleted(toolName: final n, success: final s):
        log('tool_call_completed', metadata: {'tool': n, 'success': s});
      case InterruptionDetected():
        log('interruption_detected');
      case SessionError(error: final e):
        log('session_error', metadata: {'code': e.code.name, 'message': e.message});
      case SessionWarning(message: final m):
        log('session_warning', metadata: {'message': m});
      default:
        log('event', metadata: {'type': event.runtimeType.toString()});
    }
  }

  /// Get the full timeline as a list of maps (for debug display or backend POST).
  List<Map<String, dynamic>> getTimeline() {
    return _entries.map((e) => {
      'timestamp': e.timestamp.toIso8601String(),
      'event': e.event,
      if (e.metadata != null) 'metadata': e.metadata,
    }).toList();
  }

  /// Key milestones for quick inspection.
  Map<String, String?> get milestones {
    String? find(String event) {
      try {
        final entry = _entries.firstWhere((e) => e.event == event);
        return entry.timestamp.toIso8601String();
      } catch (_) {
        return null;
      }
    }

    return {
      'session_started': find('session_started'),
      'first_audio_sent': find('audio_chunk'),
      'first_model_audio': find('audio_chunk'),
      'first_tool_call': find('tool_call_requested'),
      'session_closed': find('session_closed'),
    };
  }

  void clear() => _entries.clear();
}

class _LogEntry {
  final DateTime timestamp;
  final String event;
  final Map<String, dynamic>? metadata;

  const _LogEntry({
    required this.timestamp,
    required this.event,
    this.metadata,
  });
}
