import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api_client.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;
  PushNotificationService._();

  String? _currentToken;
  bool _initialized = false;
  Future<void>? _initializing;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  final _foregroundController =
      StreamController<ForegroundNotification>.broadcast();
  Stream<ForegroundNotification> get foregroundNotifications =>
      _foregroundController.stream;

  static GlobalKey<NavigatorState>? navigatorKey;

  Future<void> initialize(ApiClient apiClient) async {
    if (_initialized) return;
    if (_initializing != null) return _initializing!;

    _initializing = _initializeInternal(apiClient);
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initializeInternal(ApiClient apiClient) async {
    // Widget tests typically don't run Firebase.initializeApp().
    // If Firebase isn't ready, just skip FCM setup to avoid crashing tests.
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      debugPrint(
          '[PushNotificationService] Firebase not initialized; skipping FCM setup.');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notifications denied');
      return;
    }

    _currentToken = await messaging.getToken();
    if (_currentToken != null) {
      await _registerToken(apiClient, _currentToken!);
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _registerToken(apiClient, token);
    });

    _foregroundSub?.cancel();
    _foregroundSub =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _openedAppSub?.cancel();
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    _initialized = true;
  }

  Future<void> _registerToken(ApiClient apiClient, String token) async {
    try {
      await apiClient.dio.post('/auth/register-device', data: {
        'fcmToken': token,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';
    final type = message.data['type'] as String? ?? 'system';

    _foregroundController.add(ForegroundNotification(
      title: title,
      body: body,
      type: type,
    ));

    _showInAppBanner(title, body, type);
  }

  void _handleMessageOpened(RemoteMessage message) {
    final route = message.data['route'] as String? ??
        _routeForType(message.data['type'] as String?);
    if (route == null) return;
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    GoRouter.of(context).go(route);
  }

  void _showInAppBanner(String title, String body, String type) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _InAppNotificationBanner(
        title: title,
        body: body,
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> unregister(ApiClient apiClient) async {
    if (_currentToken != null) {
      try {
        await apiClient.dio.delete('/auth/register-device', data: {
          'fcmToken': _currentToken,
        });
      } catch (_) {}
    }
    _currentToken = null;
    _initialized = false;
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    _foregroundController.close();
  }

  String? _routeForType(String? type) {
    switch (type) {
      case 'event':
        return '/events';
      case 'reward':
      case 'territory_expanded':
      case 'round_complete':
      case 'achievement':
        return '/rewards';
      case 'squad':
      case 'squad_created':
      case 'squad_joined':
        return '/squad';
      default:
        return '/notifications';
    }
  }
}

class ForegroundNotification {
  final String title;
  final String body;
  final String type;
  ForegroundNotification(
      {required this.title, required this.body, required this.type});
}

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'territory_expanded':
        return Icons.map;
      case 'round_complete':
        return Icons.check_circle;
      case 'squad':
        return Icons.groups;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onDismiss,
          onVerticalDragEnd: (_) => widget.onDismiss(),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A1A2E),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(_typeIcon, color: Colors.white70, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title.isNotEmpty)
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        if (widget.body.isNotEmpty)
                          Text(
                            widget.body,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.close, color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
