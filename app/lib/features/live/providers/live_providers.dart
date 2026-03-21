import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/providers.dart';
import '../../auth/providers/auth_provider.dart';

import '../domain/live_session_state.dart';
import '../domain/live_event.dart';
import '../data/live_websocket_client.dart';
import '../data/live_message_codec.dart';
import '../data/live_token_client.dart';
import '../data/live_tool_bridge_client.dart';
import '../data/live_audio_capture_service.dart';
import '../data/live_audio_playback_service.dart';
import '../data/live_camera_stream_service.dart';
import '../data/live_mock_adapter.dart';
import '../application/live_session_controller.dart';
import '../application/live_session_logger.dart';

// ─── Infrastructure Providers ─────────────────────

final _dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});

final liveCodecProvider = Provider<LiveMessageCodec>((ref) {
  return LiveMessageCodec();
});

final liveWsClientProvider = Provider<LiveWebSocketClient>((ref) {
  final codec = ref.watch(liveCodecProvider);
  final client = LiveWebSocketClient(codec: codec);
  ref.onDispose(client.dispose);
  return client;
});

final liveTokenClientProvider = Provider<LiveTokenClient>((ref) {
  return LiveTokenClient(dio: ref.watch(_dioProvider));
});

final liveToolBridgeProvider = Provider<LiveToolBridgeClient>((ref) {
  return LiveToolBridgeClient(dio: ref.watch(_dioProvider));
});

final liveAudioCaptureProvider = Provider<AudioCaptureService>((ref) {
  final service = LiveAudioCaptureService();
  ref.onDispose(service.dispose);
  return service;
});

final liveAudioPlaybackProvider = Provider<AudioPlaybackService>((ref) {
  final service = LiveAudioPlaybackService();
  ref.onDispose(service.dispose);
  return service;
});

final liveCameraProvider = Provider<LiveCameraStreamService>((ref) {
  final service = LiveCameraStreamService();
  ref.onDispose(service.dispose);
  return service;
});

final liveMockAdapterProvider = Provider<LiveMockAdapter>((ref) {
  final adapter = LiveMockAdapter();
  ref.onDispose(adapter.dispose);
  return adapter;
});

final liveSessionLoggerProvider = Provider<LiveSessionLogger>((ref) {
  return LiveSessionLogger(
    apiClient: ref.watch(apiClientProvider),
  );
});

// ─── Session Controller ───────────────────────────

final liveSessionControllerProvider = Provider<LiveSessionController>((ref) {
  const fromEnv = bool.fromEnvironment('USE_MOCK_LIVE', defaultValue: false);
  // Release builds must never use mock live; ignore dart-define in release.
  final useMock = kReleaseMode ? false : fromEnv;

  String? authPreconditionError() {
    if (!ref.read(isAuthenticatedProvider)) {
      return 'Sign in to use Live.';
    }
    final userAsync = ref.read(currentUserProvider);
    if (userAsync.hasError) {
      return 'Could not load your profile. Sign in again or check your connection.';
    }
    if (userAsync.isLoading || userAsync.valueOrNull == null) {
      return 'Loading your profile…';
    }
    return null;
  }

  final controller = LiveSessionController(
    apiClient: ref.watch(apiClientProvider),
    ws: ref.watch(liveWsClientProvider),
    tokenClient: ref.watch(liveTokenClientProvider),
    toolBridge: ref.watch(liveToolBridgeProvider),
    audioCapture: ref.watch(liveAudioCaptureProvider),
    audioPlayback: ref.watch(liveAudioPlaybackProvider),
    camera: ref.watch(liveCameraProvider),
    logger: ref.watch(liveSessionLoggerProvider),
    telemetry: ref.watch(telemetryServiceProvider),
    mockAdapter: ref.watch(liveMockAdapterProvider),
    useMock: useMock,
    authPreconditionError: authPreconditionError,
  );

  ref.onDispose(controller.disposeSession);
  return controller;
});

// ─── State Stream ─────────────────────────────────

final liveSessionStateProvider = StreamProvider<LiveSessionState>((ref) {
  final controller = ref.watch(liveSessionControllerProvider);
  return controller.stateStream;
});

// ─── Derived Convenience Providers ────────────────

final isLiveSessionActiveProvider = Provider<bool>((ref) {
  final state = ref.watch(liveSessionStateProvider).valueOrNull;
  return state?.phase.isActive ?? false;
});

final liveTranscriptProvider = Provider<String>((ref) {
  return ref.watch(liveSessionStateProvider).valueOrNull?.modelTranscript ?? '';
});

final liveErrorProvider = Provider<LiveError?>((ref) {
  // Import LiveError from domain
  return ref.watch(liveSessionStateProvider).valueOrNull?.error;
});
