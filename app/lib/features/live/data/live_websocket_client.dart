import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../domain/live_event.dart';
import 'live_message_codec.dart';

/// Low-level WebSocket wrapper for Gemini Live sessions.
///
/// Handles connect/disconnect/reconnect lifecycle and exposes a stream
/// of [LiveEvent]s via the codec. All protocol details stay here.
class LiveWebSocketClient {
  final LiveMessageCodec _codec;

  WebSocket? _socket;
  StreamSubscription? _subscription;
  Timer? _inactivityTimer;

  final _eventController = StreamController<LiveEvent>.broadcast();
  Stream<LiveEvent> get events => _eventController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  DateTime? _connectedAt;
  DateTime? get connectedAt => _connectedAt;

  LiveWebSocketClient({LiveMessageCodec? codec})
      : _codec = codec ?? LiveMessageCodec();

  /// Open a WebSocket connection to the Gemini Live API.
  Future<void> connect({
    required String token,
    required String authType,
    required String model,
    required String systemInstruction,
    required String voiceName,
    required List<String> responseModalities,
    required List<Map<String, dynamic>> tools,
    String? websocketUrl,
    Duration connectTimeout = const Duration(seconds: 15),
  }) async {
    await disconnect(); // Clean up any existing connection

    const defaultUrl =
        'wss://generativelanguage.googleapis.com/ws/'
        'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';
    final baseUrl = websocketUrl ?? defaultUrl;
    final url = authType == 'api_key' ? '$baseUrl?key=$token' : baseUrl;

    try {
      _socket = await WebSocket.connect(
        url,
        headers: authType == 'bearer'
            ? <String, dynamic>{'Authorization': 'Bearer $token'}
            : null,
      ).timeout(
        connectTimeout,
        onTimeout: () {
          throw TimeoutException('WebSocket connect timeout', connectTimeout);
        },
      );

      _isConnected = true;
      _connectedAt = DateTime.now();

      // Send setup message
      final setupMsg = _codec.encodeSetup(
        model: model,
        systemInstruction: systemInstruction,
        voiceName: voiceName,
        responseModalities: responseModalities,
        tools: tools,
      );
      _socket!.add(setupMsg);

      // Listen for messages
      _subscription = _socket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } on TimeoutException {
      _eventController.add(const SessionError(LiveError(
        code: LiveErrorCode.wsConnectFailed,
        message: 'Connection timed out',
        recovery: LiveErrorRecovery.retry,
      )));
      rethrow;
    } on WebSocketException catch (e) {
      final lowered = e.message.toLowerCase();
      final isConfigOrAuthError =
          lowered.contains('http status code: 400') ||
          lowered.contains('http status code: 401') ||
          lowered.contains('http status code: 403') ||
          lowered.contains('http status code: 404') ||
          lowered.contains('permission') ||
          lowered.contains('unauth') ||
          lowered.contains('model') ||
          lowered.contains('not found');
      _eventController.add(SessionError(LiveError(
        code: isConfigOrAuthError
            ? LiveErrorCode.modelUnavailable
            : LiveErrorCode.wsConnectFailed,
        message: isConfigOrAuthError
            ? 'Live service configuration is unavailable right now. Please try again shortly.'
            : 'WebSocket connection failed',
        detail: e.message,
        recovery: isConfigOrAuthError
            ? LiveErrorRecovery.fatal
            : LiveErrorRecovery.retry,
      )));
      rethrow;
    } on SocketException catch (e) {
      _eventController.add(SessionError(LiveError(
        code: LiveErrorCode.wsConnectFailed,
        message: 'Network connection error',
        detail: e.message,
        recovery: LiveErrorRecovery.retry,
      )));
      rethrow;
    }
  }

  /// Send raw audio data.
  void sendAudio(Uint8List pcmData) {
    if (!_isConnected || _socket == null) return;
    _socket!.add(_codec.encodeAudioChunk(pcmData));
    _resetInactivityTimer();
  }

  /// Send an image frame.
  void sendImage(Uint8List jpegData) {
    if (!_isConnected || _socket == null) return;
    _socket!.add(_codec.encodeImageFrame(jpegData));
    _resetInactivityTimer();
  }

  /// Send text.
  void sendText(String text) {
    if (!_isConnected || _socket == null) return;
    _socket!.add(_codec.encodeText(text));
    _resetInactivityTimer();
  }

  /// Send tool response.
  void sendToolResponse(String callId, String toolName, Map<String, dynamic> result) {
    if (!_isConnected || _socket == null) return;
    _socket!.add(_codec.encodeToolResponse(callId, toolName, result));
  }

  /// Send an empty turn to kickstart the model.
  ///
  /// The Gemini Live native-audio model won't speak unprompted after setupComplete.
  /// Sending a client_content with turn_complete: true (but no parts) acts as a
  /// "user is ready, please start" signal that satisfies the model's turn-taking
  /// requirement so it generates its opening response.
  void sendKickstart() {
    if (!_isConnected || _socket == null) return;
    _socket!.add(_codec.encodeKickstart());
  }

  static const _inactivityGracePeriod = Duration(seconds: 30);

  /// Set inactivity timeout. Fires [SessionWarning] first, then
  /// [SessionClosed] after a 30s grace period if no activity resumes.
  void setInactivityTimeout(Duration timeout) {
    _inactivityTimeout = timeout;
    _inactivityTimer?.cancel();
    _inactivityCloseTimer?.cancel();
    _inactivityTimer = Timer(timeout, () {
      _eventController.add(const SessionWarning('Session inactive — closing in 30s'));
      _inactivityCloseTimer = Timer(_inactivityGracePeriod, () {
        _eventController.add(const SessionClosed(reason: 'Inactivity timeout'));
      });
    });
  }

  Duration? _inactivityTimeout;
  Timer? _inactivityCloseTimer;

  void _resetInactivityTimer() {
    if (_inactivityTimeout == null) return;
    _inactivityTimer?.cancel();
    _inactivityCloseTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout!, () {
      _eventController.add(const SessionWarning('Session inactive — closing in 30s'));
      _inactivityCloseTimer = Timer(_inactivityGracePeriod, () {
        _eventController.add(const SessionClosed(reason: 'Inactivity timeout'));
      });
    });
  }

  /// Close the WebSocket connection.
  Future<void> disconnect() async {
    _inactivityTimer?.cancel();
    _inactivityCloseTimer?.cancel();
    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    if (_socket != null) {
      await _socket!.close(WebSocketStatus.normalClosure);
      _socket = null;
    }
  }

  void _onMessage(dynamic raw) {
    final events = _codec.decode(raw);
    for (final event in events) {
      _eventController.add(event);
    }
  }

  void _onError(dynamic error) {
    final message = error.toString();
    final isAuthOrPolicy = message.contains('401') ||
        message.contains('403') ||
        message.toLowerCase().contains('policy') ||
        message.toLowerCase().contains('authentication');
    _eventController.add(SessionError(LiveError(
      code: LiveErrorCode.wsUnexpectedClose,
      message: isAuthOrPolicy ? 'Connection was rejected by server' : 'WebSocket error',
      detail: message,
      recovery: isAuthOrPolicy ? LiveErrorRecovery.fatal : LiveErrorRecovery.reconnect,
    )));
  }

  void _onDone() {
    final code = _socket?.closeCode;
    final reason = _socket?.closeReason;
    _isConnected = false;

    if (code == WebSocketStatus.normalClosure) {
      _eventController.add(SessionClosed(closeCode: code, reason: reason));
    } else {
      // Don't reconnect on auth/policy errors — would loop. Reconnect only for transient drops.
      final isPolicyOrAuth = code == 1008 /* policy */ || code == 1002 /* protocol */ || code == 1003 /* unsupported */;
      _eventController.add(SessionError(LiveError(
        code: LiveErrorCode.wsUnexpectedClose,
        message: isPolicyOrAuth ? 'Connection was rejected. Check your session and try again.' : 'Connection closed unexpectedly',
        detail: 'Code: $code, Reason: $reason',
        recovery: isPolicyOrAuth ? LiveErrorRecovery.fatal : LiveErrorRecovery.reconnect,
      )));
    }
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
