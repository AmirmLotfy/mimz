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
    required String model,
    required String systemInstruction,
    required String voiceName,
    required List<String> responseModalities,
    required List<Map<String, dynamic>> tools,
    Duration connectTimeout = const Duration(seconds: 10),
  }) async {
    await disconnect(); // Clean up any existing connection

    final url =
        'wss://generativelanguage.googleapis.com/ws/'
        'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent'
        '?key=$token';

    try {
      _socket = await WebSocket.connect(url).timeout(
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
      _eventController.add(SessionError(LiveError(
        code: LiveErrorCode.wsConnectFailed,
        message: 'WebSocket connection failed',
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

  /// Set inactivity timeout. Fires [SessionWarning] when exceeded.
  void setInactivityTimeout(Duration timeout) {
    _inactivityTimeout = timeout;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeout, () {
      _eventController.add(const SessionWarning('Session inactive — will close soon'));
    });
  }

  Duration? _inactivityTimeout;

  void _resetInactivityTimer() {
    if (_inactivityTimeout == null) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout!, () {
      _eventController.add(const SessionWarning('Session inactive — will close soon'));
    });
  }

  /// Close the WebSocket connection.
  Future<void> disconnect() async {
    _inactivityTimer?.cancel();
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
    _eventController.add(SessionError(LiveError(
      code: LiveErrorCode.wsUnexpectedClose,
      message: 'WebSocket error',
      detail: error.toString(),
      recovery: LiveErrorRecovery.reconnect,
    )));
  }

  void _onDone() {
    final code = _socket?.closeCode;
    final reason = _socket?.closeReason;
    _isConnected = false;

    if (code == WebSocketStatus.normalClosure) {
      _eventController.add(SessionClosed(closeCode: code, reason: reason));
    } else {
      _eventController.add(SessionError(LiveError(
        code: LiveErrorCode.wsUnexpectedClose,
        message: 'Connection closed unexpectedly',
        detail: 'Code: $code, Reason: $reason',
        recovery: LiveErrorRecovery.reconnect,
      )));
    }
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
